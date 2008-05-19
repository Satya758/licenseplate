% Filter out characters on plate. Turn down to 8 colors.
% Correctness: 63,7%/72,7% 

function plateCoords = DetectQuant(inputImage)

  scaleFactor = 0.25;

  %filterSize = 8;


  %showImages = false;
  showImages = true;


  % Read image from file
  origImage = imread(inputImage);

  % Convert image to greyscale
  grayImage = rgb2gray(origImage);

  % Resize image
  resizedImage = imresize(grayImage, scaleFactor);


  %%%%%%%%%%%%%%%%%%%%%%%%
  % Apply filter         %
  %%%%%%%%%%%%%%%%%%%%%%%%

  % Get image height and width
  [imHeight, imWidth] = (size(resizedImage));


  % Set pixels to max intensity of neighbourhood
  fun = @(x) max(max(x));
  filteredImage = nlfilter(resizedImage ,'indexed', [5 7], fun);

  
  % Cut down number of intensities to 8
  quantImage = (floor(filteredImage / 32))+1; % 8 colours
  %quantImage = (floor(filteredImage / 64))+1; % 4 colours
 
  % Matrix to hold multi dimensional binary image
  mDimBin = zeros(imHeight, imWidth, 16);

  % Create binary image for each color
  for y = 1:imHeight
   for x = 1:imWidth
     mDimBin(y, x, quantImage(y,x)) = 1;
   end
  end
  
  % Cleanup each binary image
  for x = 1:16
     mDimBin(:,:,x) = BinImgCleanup(mDimBin(:,:,x), scaleFactor);
  end

  % Show channels
  %{
  figure(800);
  for x = 1:16
    subplot(4, 4, x);
    imshow(mDimBin(:,:,x));
  end
  %}



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Create binary image       %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %Collapse binary images into one

  binImage = zeros(imHeight,imWidth);
  % We need to erode each area so that they will not
  % merge when the channels are merged
  shape = strel('square',3);
  for i = 1:16
    %binImage = binImage + mDimBin(:,:,i);
    binImage = binImage + imerode(mDimBin(:,:,i),shape);
  end

  binImage = im2bw(binImage, 0.5);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Cleanup bin image         %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cleanedBinImage = BinImgCleanup(binImage, scaleFactor);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Connected components     %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%

  [conComp,numConComp] = (bwlabel(cleanedBinImage,4));
  

  %%%%%%%%%%%%%%%%%%%%%%
  % Get best candidate %
  %%%%%%%%%%%%%%%%%%%%%%

  plateCoords = GetBestCandidate(conComp, resizedImage, scaleFactor);


  %%%%%%%%%%%%%%%
  % Images      %
  %%%%%%%%%%%%%%%

  if showImages


    figure(100);
  
    subplot(2,2,1);
    imshow(filteredImage);
    %imwrite(filteredImage,'DetectQuant-filteredImage.png','PNG');

    subplot(2,2,2);
    imshow(quantImage,[]);
    %imwrite(32*quantImage,'DetectQuant-quantImage.png','PNG');

    subplot(2,2,3);
    imshow(cleanedBinImage);
    %imwrite(binImage,'DetectQuant-binary.png','PNG');


    % Show candidate
    subplot(2,2,4);
    if sum(plateCoords) > 0
      imshow(origImage(plateCoords(3):plateCoords(4),plateCoords(1):plateCoords(2)));
    else
      imshow(zeros(2,2));
    end


  end


  % Make plate a little higher 
  if sum(plateCoords) > 0
    plateCoords = plateCoords + [ -10 10 -10 10 ];
  end



end % function 
