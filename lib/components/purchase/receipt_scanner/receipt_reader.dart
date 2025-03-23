import 'dart:convert';
import 'dart:io';

import 'package:csocsort_szamla/components/helpers/border_shimmer.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum ProcessingState { idle, processing, done, error }

class ReceiptReader extends StatefulWidget {
  const ReceiptReader({
    super.key,
    required this.onInformation,
    required this.maxPictureSize,
    this.initialInformation,
  });

  final double maxPictureSize;
  final Function(ReceiptInformation? information) onInformation;
  final ReceiptInformation? initialInformation;

  @override
  State<ReceiptReader> createState() => _ReceiptReaderState();
}

class _ReceiptReaderState extends State<ReceiptReader> with SingleTickerProviderStateMixin {
  File? _image;
  ImagePicker? _imagePicker;
  ProcessingState _processingState = ProcessingState.idle;

  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();

    if (widget.initialInformation != null) {
      _image = widget.initialInformation!.imageFile;
      _processingState = ProcessingState.done;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      curve: Curves.easeInOut,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        clipBehavior: Clip.antiAlias,
        child: _image != null
            ? ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                    child: Align(
                      child: Container(
                        constraints: BoxConstraints(maxHeight: widget.maxPictureSize),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Image.file(
                              _image!,
                              fit: BoxFit.contain,
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) {
                                  return child;
                                }
                                if (frame == null) {
                                  return Container(
                                    height: widget.maxPictureSize,
                                  );
                                }
                                return child;
                              },
                            ),
                            if (_processingState == ProcessingState.processing)
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.2,
                                  child: Container(color: Colors.black),
                                ),
                              ),
                            if (_processingState == ProcessingState.processing)
                              Positioned.fill(
                                child: BorderShimmer(
                                  borderWidth: 25,
                                  gradientColors: [
                                    AppTheme.themes[ThemeName.dodoLight]!.colorScheme.primary,
                                    AppTheme.themes[ThemeName.dodoLight]!.colorScheme.secondary,
                                    AppTheme.themes[ThemeName.dodoLight]!.colorScheme.primary,
                                  ],
                                  duration: Duration(seconds: 2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_processingState == ProcessingState.processing)
                          Text(
                            'receipt-scanner.processing'.tr(),
                            style: Theme.of(context).textTheme.labelSmall,
                          )
                        else if (_processingState == ProcessingState.error)
                          Text(
                            'receipt-scanner.error'.tr(),
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        IconButton.filled(
                          onPressed: _processingState != ProcessingState.processing ? _reset : null,
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                      child: Center(
                        child: Text(
                          'receipt-scanner.select-image'.tr(),
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 18,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(onPressed: () => _getImage(ImageSource.gallery), icon: Icon(Icons.photo_library)),
                        SizedBox(width: 16),
                        IconButton.filled(onPressed: () => _getImage(ImageSource.camera), icon: Icon(Icons.camera_alt)),
                      ],
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Future _reset() async {
    setState(() {
      _image = null;
      _processingState = ProcessingState.idle;
    });
    widget.onInformation(null);
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _processFile();
    }
  }

  Future _processFile() async {
    try {
      setState(() {
        _processingState = ProcessingState.processing;
      });
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash-lite',
        systemInstruction: Content.system("""Your task is to extract structured information from photos of receipts and return it in JSON format. Ensure that the extracted data is accurate and complete. Receipts may be in any language. Accurately extract information regardless of the language used. Ensure that all extracted text (store names, item names) remains in its original language, but standardize the currency code using ISO 4217. Follow these rules strictly:
        Identify the store name exactly as printed on the receipt.
        Extract the total cost and ensure it is in the correct currency (ISO 4217 format).
        List all items with their exact names, prices, and any applicable discounts.
        If an item has a discount, match it precisely to the correct item. Discounts may not be explicitly labeled as such, so use context to determine if a price is a discount. Usually, the discount is listed below the item name.
        Ensure that numeric values are always properly formatted (e.g., no currency symbols in the number field, decimals as needed).
        Do not hallucinate missing data—if something cannot be read, return null instead of guessing.
        Check for common OCR errors such as misinterpreted characters (e.g., '0' vs. 'O', '1' vs. 'I')."""),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema(
            SchemaType.object,
            properties: {
              'store_name': Schema(SchemaType.string),
              'total_cost': Schema(SchemaType.number),
              'currency_code_iso_4217': Schema(SchemaType.string),
              'items': Schema(
                SchemaType.array,
                items: Schema(
                  SchemaType.object,
                  properties: {
                    'item_name': Schema(SchemaType.string),
                    'cost': Schema(SchemaType.number),
                    'discount': Schema(SchemaType.number),
                  },
                ),
              ),
            },
          ),
          maxOutputTokens: 5000,
        ),
      );
      final file = await _image!.readAsBytes();
      final prompt = [
        Content.multi([
          InlineDataPart('image/png', file),
          TextPart('Parse the receipt.'),
        ])
      ];
      final response = await model.generateContent(prompt);
      var information = ReceiptInformation.fromJson(jsonDecode(response.text!), _image!);
      widget.onInformation(information);
      setState(() {
        _processingState = ProcessingState.done;
      });
    } catch (e) {
      setState(() {
        _processingState = ProcessingState.error;
      });
    }
  }
}
