  //batch analysis - Alveolar macrophage phenotyping
   
  Dialog.create("Assign Channel ID");
  Dialog.addString("CY5 Image Suffix:", "w4"); //iNOS
  Dialog.addString("Green Image Suffix:", "w2"); //CD68
  Dialog.addString("Red Image Suffix:", "w3"); //CD206
  Dialog.addString("Blue Image Suffix:", "w1"); //dapi  
   
  
  //Dialog.show();//delete this line to hide the dialog box if you always have the same image suffix per color
    
  cy5Suffix = Dialog.getString() + ".";
  greenSuffix = Dialog.getString() + ".";
  redSuffix = Dialog.getString() + ".";
  blueSuffix = Dialog.getString() + ".";
  
  function sort(list) {
    for (i = 0; i < list.length - 1; i++) {
        for (j = i + 1; j < list.length; j++) {
            if (list[j] < list[i]) {
                temp = list[i];
                list[i] = list[j];
                list[j] = temp;
            }
        }
    }
    return list;
}
    batchCount();
run("Set Measurements...", "area mean min area_fraction display redirect=None decimal=3"); 

  function batchCount() {
      dir1 = getDirectory("Choose Image Folder to Analyze");
      name = File.getName(dir1);
      list = getFileList(dir1);
      
      dir2 = getDirectory("Select Folder to Save Results");
      list = getFileList(dir1);
      list = sort(list);
      setBatchMode(false);
      //set to false allows us to see the images load as imagej is processing for manual threshold. set to [true] for blind folder batch processing
      n = list.length;
      if ((n%4)!=0)
         exit("The number of files must be a multiple of 4");
      stack = 0;
      first = 0;
      for (i=0; i<n/4; i++) {
          showProgress(i+1, n/4);
          cy5="?";  red="?"; green="?"; blue="?";   
          for (j=first; j<first+4; j++) {
             if (indexOf(list[j], cy5Suffix)!=-1)
                  cy5 = list[j];           
             if (indexOf(list[j], greenSuffix)!=-1)
                  green = list[j];
             if (indexOf(list[j], redSuffix)!=-1)
                  red = list[j];
             if (indexOf(list[j], blueSuffix)!=-1)
                  blue = list[j];
          }
          
          
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
//1.calculating the well area for your region of interest        
	open(dir1+green);
    w1=getTitle();
    run("Enhance Contrast", "saturated=0.35");
    run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");
    run("8-bit");
    run("Set Measurements...", "area mean standard modal min perimeter feret's integrated median display redirect=None decimal=3");
    setAutoThreshold("Mean dark");
  	run("Convert to Mask");
  	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	rename("background_area");
	b=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "background+" + list[j-4] + ".jpg");
	close("Results");
	
// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Summary");
	close("Results");	

	

///3. identifying CD68 area; need to change thresholding algorithm if it doesn't work on your images
	open(dir1+green);
	
	//3a.some background alteration
	run("Enhance Contrast", "saturated=0.35");
	setOption("ScaleConversions", true);
	run("Unsharp Mask...", "radius=1 mask=0.60");
	run("Subtract Background...", "rolling=300");
	run("8-bit");
	setAutoThreshold("Triangle dark"); //also optimize this based on your staining
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");	//20x magnification pixel to um conversion
  	run("Analyze Particles...", "size=10-500 circularity=0-1.00 include show=Masks");
	rename("CD68_area"); 
	
	//segmenting CD68 mask (small, medium, big particles)
	selectWindow("CD68_area");
	run("Analyze Particles...", "size=150-Infinity circularity=0-1.00 include show=Masks");
	rename("CD68_count_big");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=0.3");
	
	selectWindow("CD68_area");
	run("Analyze Particles...", "size=100-149 circularity=0-1.00 include show=Masks");
	rename("CD68_count_medium");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=1");
	
	selectWindow("CD68_area");
	run("Analyze Particles...", "size=10-99 circularity=0-1.00 include show=Masks");
	rename("CD68_count_small");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Fill Holes");	
	run("Adjustable Watershed", "tolerance=0.5");

	//putting small, medium, big CD68 masks together for final mask
	imageCalculator("Add create", "CD68_count_big","CD68_count_medium");
	imageCalculator("Add create", "Result of CD68_count_big","CD68_count_small");
	rename("CD68_count_final");	
	rename("CD68_count+"+ list[j-4]); 
	w3=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "CD68_count+" + list[j-4] + ".jpg"); 
	close();
	
	selectWindow("CD68_area");
	rename("CD68_area+"+ list[j-4]); 	
	w4=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "CD68_area+" + list[j-4] + ".jpg"); 
	close();
	
	close("CD68_count_small");
	close("CD68_count_big");
	close("CD68_count_medium"); 
	

///4. identifying CD206 area; need to change thresholding algorithm if it doesn't work on your images (lines 46-50)
	open(dir1+red);
	
	//3a.some background alteration
	run("Enhance Contrast", "saturated=0.35");
	setOption("ScaleConversions", true);
	run("Unsharp Mask...", "radius=1 mask=0.60");
	run("Subtract Background...", "rolling=300");
	run("8-bit");
	setAutoThreshold("Triangle dark"); //also optimize this based on your staining
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");	
  	run("Analyze Particles...", "size=10-500 circularity=0-1.00 include show=Masks");
	rename("CD206_area"); 
	
	//segmenting CD206 mask (small, medium, big particles)
	selectWindow("CD206_area");
	run("Analyze Particles...", "size=150-Infinity circularity=0-1.00 include show=Masks");
	rename("CD206_count_big");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=0.3");
	
	selectWindow("CD206_area");
	run("Analyze Particles...", "size=100-149 circularity=0-1.00 include show=Masks");
	rename("CD206_count_medium");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=1");
	
	selectWindow("CD206_area");
	run("Analyze Particles...", "size=10-99 circularity=0-1.00 include show=Masks");
	rename("CD206_count_small");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Fill Holes");	
	run("Adjustable Watershed", "tolerance=0.5");

	//putting small, medium, big CD206 masks together for final mask
	imageCalculator("Add create", "CD206_count_big","CD206_count_medium");
	imageCalculator("Add create", "Result of CD206_count_big","CD206_count_small");
	rename("CD206_count_final");	
	rename("CD206_count+"+ list[j-4]); 
	w5=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "CD206_count+" + list[j-4] + ".jpg"); 
	close();
	
	selectWindow("CD206_area");
	rename("CD206_area+"+ list[j-4]); 	
	w6=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "CD206_area+" + list[j-4] + ".jpg"); 
	close();
	
	close("CD206_count_small");
	close("CD206_count_big");
	close("CD206_count_medium"); 
	
	selectWindow("background_area");
	run("Create Selection");
///5. identifying iNOS area; need to change thresholding algorithm if it doesn't work on your images (lines 46-50)
	open(dir1+cy5);
	
	//3a.some background alteration
	run("Enhance Contrast", "saturated=0.35");
	setOption("ScaleConversions", true);
	run("Unsharp Mask...", "radius=1 mask=0.60");
	run("Subtract Background...", "rolling=300");
	run("8-bit");
	setAutoThreshold("Triangle dark"); //also optimize this based on your staining
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");	
  	run("Analyze Particles...", "size=10-500 circularity=0-1.00 include show=Masks");
	rename("iNOS_area"); 
	close("Results");
	
	//segmenting iNOS mask (small, medium, big particles)
	selectWindow("iNOS_area");
	run("Analyze Particles...", "size=150-Infinity circularity=0-1.00 include show=Masks");
	rename("iNOS_count_big");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=0.3");
	
	selectWindow("iNOS_area");
	run("Analyze Particles...", "size=100-149 circularity=0-1.00 include show=Masks");
	rename("iNOS_count_medium");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=1");
	
	selectWindow("iNOS_area");
	run("Analyze Particles...", "size=10-99 circularity=0-1.00 include show=Masks");
	rename("iNOS_count_small");	
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Adjustable Watershed", "tolerance=0.5");

	//putting small, medium, big iNOS masks together for final mask
	imageCalculator("Add create", "iNOS_count_big","iNOS_count_medium");
	imageCalculator("Add create", "Result of iNOS_count_big","iNOS_count_small");
	rename("iNOS_count_final");	
	rename("iNOS_count+"+ list[j-4]); 
	w7=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "iNOS_count+" + list[j-4] + ".jpg"); 
	close();
	
	selectWindow("iNOS_area");
	rename("iNOS_area+"+ list[j-4]); 	
	w8=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "iNOS_area+" + list[j-4] + ".jpg");
	close();
	
	close("iNOS_count_small");
	close("iNOS_count_big");
	close("iNOS_count_medium"); 



//6. Colocalzing CD68 counts with CD206 counts
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
	selectWindow(w3); //w3 = CD68 count mask
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");	
	run("Analyze Particles...", "size=0-Infinity include add");
	selectWindow(w5); //w5 = CD206 count mask
	
	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

	//Here, you are comparing particles in the ROI manager to your background_area and delete any particles that overlap less than 50%.
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<50) { // 50% overlap
		      measurements[l] = l;
		  }
	}
			roiManager("select", measurements);
			roiManager("Delete");

	run("Select None");
	close("Results");


	// selecting and combining all remaining ROI particles into one mask image
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
	roiManager("Combine");

	// create new overlay image with ROIs
	image_width = getWidth();
	image_height = getHeight();
	newImage("untitled", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	rename("CD206_CD68_count"); 
	selectWindow("CD206_CD68_count");
	rename("CD206_CD68_count+"+ list[j-4]); 
	CD206_CD68_count=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "CD206_CD68_count+" + list[j-4] + ".jpg"); 
	close("untitled");

// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Summary");
	close("Results");
	
//7. Colocalzing CD68 counts with iNOS counts
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
	selectWindow(w3); //w3 = CD68 count mask
	run("Select None");
	run("Remove Overlay");
	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");	
	run("Analyze Particles...", "size=0-Infinity include add");
	selectWindow(w7); //w5 = CD206 count mask
	
	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

	//Here, you are comparing particles (CD68) in the ROI manager to your iNOS and delete any particles that overlap less than 50%.
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<20) { // 20% overlap
		      measurements[l] = l;
		  }
	}
			roiManager("select", measurements);
			roiManager("Delete");

	run("Select None");
	close("Results");


	// selecting and combining all remaining ROI particles into one mask image
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
	roiManager("Combine");

	// create new overlay image with ROIs
	image_width = getWidth();
	image_height = getHeight();
	newImage("untitled", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	rename("iNOS_CD68_count"); 
	selectWindow("iNOS_CD68_count");
	rename("iNOS_CD68_count+"+ list[j-4]); 
	iNOS_CD68_count=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "iNOS_CD68_count+" + list[j-4] + ".jpg"); 
	close("untitled");

// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Summary");
	close("Results");
	
//8. Colocalzing CD68 areas with iNOS or CD206 areas
	imageCalculator("AND create", w4,w6); //w4= CD68 area, w6= CD206 area
	rename("CD206_CD68_area"); 
	selectWindow("CD206_CD68_area");
	rename("CD206_CD68_area+"+ list[j-4]); 
	CD206_CD68_area=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "CD206_CD68_area+" + list[j-4] + ".jpg");
	
	
	imageCalculator("AND create", w4,w8); //w4= CD68 area, w8= iNOS area
	rename("iNOS_CD68_area"); 
	selectWindow("iNOS_CD68_area");
	rename("iNOS_CD68_area+"+ list[j-4]); 
	iNOS_CD68_area=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "iNOS_CD68_area+" + list[j-4] + ".jpg"); 
	
	
//opening final masks to record results
selectImage(w3); //CD68 count
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w5); //CD206 count
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w7); //iNOS count
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(CD206_CD68_count);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(iNOS_CD68_count); 
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results


selectImage(w4); //CD68 area
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w6); //CD206 area
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w8); //iNOS area
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(CD206_CD68_area);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(iNOS_CD68_area);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(b); 
rename("background_area+" + list[j-4]);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results


// save results	
	selectWindow("Summary");
	saveAs("results", dir2+"Lung_macrophage+" + list[j-4] + ".txt");
	//roiManager("Delete");
	close("Results");
	close("Summary");
	close("Threshold");  
	close("ROI Manager");
	close("Untitled");
	close("Results");
    close("*");
    close("*.txt");
	run("Close All");
	showProgress(i, list.length);
          first += 4;
      }}



waitForUser("complete, Click Okay");


