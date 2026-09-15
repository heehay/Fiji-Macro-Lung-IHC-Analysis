  //batch analysis - fibrosis endpoints
   
  Dialog.create("Assign Channel ID");

  Dialog.addString("Green Image Suffix:", "w2"); //Collagen 1a1
  Dialog.addString("CY5 Image Suffix:", "w3"); //CTHRC1
  Dialog.addString("Blue Image Suffix:", "w1"); //dapi  
   
  
  //Dialog.show();//delete this line to hide the dialog box if you always have the same image suffix per color
    
  greenSuffix = Dialog.getString() + ".";
  cy5Suffix = Dialog.getString() + ".";
  //redSuffix = Dialog.getString() + ".";
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
	run("Set Measurements...", "area mean standard median integrated redirect=None decimal=3");	

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
      if ((n%3)!=0)
         exit("The number of files must be a multiple of 3");
      stack = 0;
      first = 0;
      for (i=0; i<n/3; i++) {
          showProgress(i+1, n/3);
          cy5="?";  green="?"; blue="?";   
          for (j=first; j<first+3; j++) {
             if (indexOf(list[j], cy5Suffix)!=-1)
                  cy5 = list[j];           
             if (indexOf(list[j], greenSuffix)!=-1)
                  green = list[j];
             if (indexOf(list[j], blueSuffix)!=-1)
                  blue = list[j];
          }
          
   	run("Set Measurements...", "area mean standard modal min median area_fraction display redirect=None decimal=3");         
//1.calculating the well area for your region of interest        
	open(dir1+blue);   //dapi
	run("Set Scale...", "distance=1 known=0.3249 unit=µm global"); //20X on XLS imager      
	dapiTitle = getTitle();   // w1
	open(dir1+green);  //collagen
	run("Set Scale...", "distance=1 known=0.3249 unit=µm global"); //20X on XLS imager      
	colTitle  = getTitle();   // w2

	// make a reference image that captures "any tissue"
	imageCalculator("Max create", dapiTitle, colTitle);	//doing this to catch any tissue
	run("Gaussian Blur...", "sigma=2");     // helps connect tissue
	run("8-bit");
	setAutoThreshold("IsoData dark");      // try "Li dark" if Triangle fails
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");
	rename("background_area");
	b=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "background+" + list[j-3] + ".jpg");
	close("Results");
	close(dapiTitle);
	close(colTitle);

///3. Percent area = identifying collagen area; need to change thresholding algorithm if it doesn't work on your images (lines 46-50)
	open(dir1+green);
	w2=getTitle();
	run("Set Scale...", "distance=1 known=0.3249 unit=µm global"); //20X on XLS imager
	run("Set Measurements...", "area mean standard median integrated redirect=None decimal=3");
	close("Results");              // important: avoid stale Results
	run("Select None");
	//selectImage("background_area"); 
	//run("Create Selection"); 
	selectImage(w2); 
	//run("Restore Selection"); 
	run("Measure"); 
	image_mean = getResult("Mean", 0);
	close("Results");
	//selectImage(w2); 
	run("Subtract...", "value=" + image_mean);
	run("Subtract Background...", "rolling=300");
	run("Enhance Contrast", "saturated=0.35 normalize");
	run("8-bit");

	//setAutoThreshold("Moments dark");
	setAutoThreshold("IJ_IsoData dark");
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Set Measurements...", "area mean standard median integrated redirect=None decimal=3");         
  	rename("collagen"); 
	rename("collagen+"+ list[j-3]); 
	w2=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "collagen+" + list[j-3] + ".jpg"); //this line will save collagen mask of each image to results folder. it's helpful to identify any unusual masks.	
	close();
	close("Results");
	

///4. Percent area = identifying CTHRC1 area; need to change thresholding algorithm if it doesn't work on your images (lines 46-50)
	open(dir1+cy5);
	w3=getTitle();
	run("Set Scale...", "distance=1 known=0.3249 unit=µm global"); //20X on XLS imager
	run("Set Measurements...", "area mean standard median integrated redirect=None decimal=3");
	
	//4a.some background alteration
	run("Select None");
	close("Results");
    
    image_width = getWidth();
    image_height = getHeight();

	width = (getWidth()*0.05);
	//	print(width);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	changeValues(0, 0, getResult("Mean",0));
	close("Results");

	run("Subtract Background...", "rolling=300");
	
	selectImage(b);
	run("Create Selection");
	close("Results");
	roiManager("Reset");
	roiManager("Add");
    
    selectImage(w3);
    roiManager("Select", 0);
	
	selectImage(w3);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	avg = getResult("Mean", 0);
	run("Subtract...", "value=avg");	

	run("8-bit");
	setAutoThreshold("IJ_IsoData dark");
	run("Convert to Mask");
	run("Set Measurements...", "area mean standard median integrated redirect=None decimal=3");         
	
	rename("cthrc1"); 
	rename("cthrc1+"+ list[j-3]); 
	w3=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "cthrc1+" + list[j-3] + ".jpg"); //this line will save mask of each image to results folder. it's helpful to identify any unusual masks.	
	close();
	close("Results");

//5. MFI measurement = identifying collagen area	
	open(dir1+green);
	rawTitle = getTitle();
	run("Set Scale...", "distance=1 known=0.3249 unit=µm global"); //20X on XLS imager      
  	run("Set Measurements...", "area mean standard median integrated redirect=None decimal=3");
	selectImage(b);
	run("Create Selection");
	roiManager("Reset");
	roiManager("Add");
  	selectWindow(rawTitle);
  	roiManager("Select", 0);
	run("Measure");
	close(rawTitle);
	
//6. MFI measurement = identifying cthrc1 area
	open(dir1+cy5);
	rawTitle2 = getTitle();
	run("Set Scale...", "distance=1 known=0.3249 unit=µm global"); //20X on XLS imager      
    run("Set Measurements...", "area mean standard median integrated redirect=None decimal=3");
	selectImage(b);
	run("Create Selection");
	roiManager("Reset");
	roiManager("Add");
  	selectWindow(rawTitle2);
  	roiManager("Select", 0);
	run("Measure");
	close(rawTitle2);
	roiManager("Reset");
	

	
//opening final masks to record results
selectImage(w2); //collagen
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w3); //cthrc1
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(b); 
rename("background_area+" + list[j-3]);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results


// save results	
	selectWindow("Summary");
	saveAs("results", dir2+"%Area_fibrogenesis+" + list[j-3] + ".txt");
	selectWindow("Results");
	saveAs("results", dir2+"MFI_fibrogenesis+" + list[j-3] + ".txt");
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
          first += 3;
      }}



waitForUser("complete, Click Okay");


