# Fiji-Macro-Lung-IHC-Analysis
Uploaded files are Fiji macros customized to do batch analyze in vivo rat immunohistochemistry lung images for quantitative analysis.
All thresholding algorithms used in the macros are available on Fiji software (ImageJ version 1.54f, National Institutes of Health; Bethesda, MD, USA).

## Contributors:
- Heui Hye (Heehay) Park

**All thresholding algorithms and background correction methods need to be optimized for each biomarker based on the quality of IHC, resolution of images, and batch-to-batch variations (if applicable). 

**Additional adjustable watershed plugin is necessary to run the macros.
    Adjustable watershed plugin from:
        
        [media/adjustable-watershed/Adjustable_Watershed.java ](https://github.com/imagej/imagej.github.io/blob/main/media/adjustable-watershed/Adjustable_Watershed.java)
        
        https://imagej.net/plugins/adjustable-watershed/adjustable-watershed

- Lung section_marophage_qIHC: Analyzes macrophage cell count and percent area.
This code has been customized for IHC co-stained for: CD68, CD206, iNOS.

- Lung section_fibrogenesis_qIHC: Analyzes CTHRC1 and collagen I  percent area. 
This code has been customized for IHC stained for: CTHRC1 and collagen I.

