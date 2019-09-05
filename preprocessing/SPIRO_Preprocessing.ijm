//requirements for file organization
//main directory containing all images sorted by plate into subdirectories
//requirements for image naming
//plate1-date20190101-time000000-day

//user selection of main directory
maindir = getDirectory("Choose a Directory ");
list = getFileList(maindir);
processMain1(maindir);

///set up recursive processing of a main directory which contains multiple subdirectories   
function processMain1(maindir) {
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")) {
			subdir = maindir+list[i];
			sublist = getFileList(subdir);
			platename = File.getName(subdir);
			processSub1(subdir);
		}
	}
}

function processSub1(subdir) {
	print("Processing "+ subdir+ "...");
	setBatchMode(false);
	run("Image Sequence...", "open=["+subdir+sublist[0]+"]+convert sort use");
	stack1 = getTitle();
	if (i==0)
	scale();
	crop();
	register();
	print(i+1 +"/"+list.length + " folders processed.");
}


function scale() {
	print("Setting scale...");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
	setTool("line");
	run("Set Measurements...", "area bounding display redirect=None decimal=3");
	waitForUser("Setting the scale. Please zoom in on the scale bar and hold the SHIFT key while drawing a line corresponding to 1cm.");
	run("Measure");
	length = getResult('Length', nResults-1);
	while (length==0 || isNaN(length)) {
        waitForUser("Line selection required.");
        run("Measure");
		length = getResult('Length', nResults-1);
	}
	angle  = getResult('Angle', nResults-1);
	while (angle != 0) {
			waitForUser("Line must not be at an angle.");
			run("Measure");
			angle  = getResult('Angle', nResults-1);
	}
	Table.rename("Results", "Positions");
	waitForUser("1cm corresponds to " + length + " pixels. Click OK if correct.");
	run("Set Scale...","distance="+length+" known=1 unit=cm global");
	}

//for cropping of images into a smaller area to allow faster processing
function crop() {
	print("Cropping...");
	nR = Table.size;
	bx = Table.get("BX", nR-1);
	by = Table.get("BY", nR-1);
	length = Table.get("Length", nR-1);
	xmid = (bx+length/2);
	dx = 13;
	dy = 10.5;
	toUnscaled(dx, dy);
	x1 = xmid - dx;
	y1 = by - dy;
	width = 14;
	height = 12.5;
	toUnscaled(width, height);
	makeRectangle(x1, y1, width, height);
	run("Crop");
}

function register() {
	print("Registering...");
	run("8-bit");
	run("Duplicate...", "duplicate");
	stack2 = getTitle();
	run("Subtract Background...", "rolling=30 stack");
	tfn = subdir+"/Transformation Matrices/";
	run("MultiStackReg", "stack_1="+stack2+" action_1=Align file_1="+tfn+" stack_2=None action_2=Ignore file_2=[] transformation=Translation save");
	close(stack2);
	run("MultiStackReg", "stack_1="+stack1+" action_1=[Load Transformation File] file_1="+tfn+" stack_2=None action_2=Ignore file_2=[] transformation=[Translation]");
	selectWindow(stack1);
	saveAs("Tiff", subdir+platename+"_registered.tif");
	run("Z Project...", "projection=[Standard Deviation]");
	zproj = getTitle();
	saveAs("Tiff", subdir+platename+"Z-Projection.tif");
	close();
	close();
}

