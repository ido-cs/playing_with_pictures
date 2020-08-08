


function Task2(img_path)
I = imread(img_path);

[isYellow, amountOfYellow] = isYellowCar(I,16);

readPlate(I, isYellow, amountOfYellow);
end

function[isYellow, howMuchYellow] =  isYellowCar(I,per)
%{
hyper parameters that decide what is yellow.
we return is the precent of yellow in pic is above "per" and how many
pixles are yellow.
%}
hsv = rgb2hsv(I);
generalMaxH = 0.14;
generalMinH = 0.1;
isYellow = false;

amountOfColor  = (hsv(:,:,1) >= generalMinH & hsv(:,:,1) <=generalMaxH);

percentColor =  100*(sum(sum(amountOfColor))/(size(I,1)*size(I,2))); 
howMuchYellow = sum(sum(amountOfColor));
if percentColor > per %threashhold before we decide its a yellow car
    isYellow = true;

end
end

function readPlate(I, isYellow, amountOfYellow)
%{
parameters that more cerfully check whats yellow in HSV domain
and what is yellow in RGB domain. in hsv we use bounderies and in RGB we
use L1 only if there is a lot of yellow, otherwise no need.
%}

normalMinH = 0.05;
normalMaxH = 0.14;
normalMinS = 0.4;
normalMinV = 0.4;


red = 160;
green = 110;
blue = 20;

imgSize = sum(size(I));
im = I;
hsv = rgb2hsv(im);
%L1 distance
redD = abs(im(:,:,1)-red);
greenD = abs(im(:,:,2)-green);
blueD = abs(im(:,:,3)-blue);

mask2 = (redD + greenD + blueD <20)| ~(isYellow) ;
mask2 = imfill(mask2,'holes');


mask  = (hsv(:,:,1) >=normalMinH & hsv(:,:,1) <=normalMaxH)&...
(hsv(:,:,2) >=normalMinS) & (hsv(:,:,3)>=normalMinV);


mask3 = mask.*mask2;

if isYellow 
    %{
    for yellow cars (or pics with a lot of yellow) we look for something
    that looks like a ractangle that isnt too big (relitive to the amount
    of yellow pixles) using Extent and area
    %}
    mask3 = imfill(mask3, 'holes');

    [labeledImage, numberOf] = bwlabel(mask3);
    blobMeasurements = regionprops(labeledImage,'Extent', 'Area'); 
    area  = [blobMeasurements.Area];
    extent = [blobMeasurements.Extent];


    bound = 0.2;

    %hyperparameters that works best.
     for blob = 1: numberOf
        if extent(blob) < bound ||...
           area(blob) < imgSize/(1.5) ||...
           area(blob) > amountOfYellow / 10
            mask3 (labeledImage == blob) =0;
        end
     end
mask3 = imfill(mask3,'holes');
end


mask3 = uint8(mask3);
im(:,:,1)=im(:,:,1).*mask3; 
im(:,:,2)=im(:,:,2).*mask3; 
im(:,:,3)=im(:,:,3).*mask3; 
figure(5)
imshow(rgb2hsv(im))
impixelinfo();
%taking the largest yellow blob from the picture
im2 = im;
CC = bwconncomp(im);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx] = max(numPixels);

im2(CC.PixelIdxList{idx}) = 0;

I2= I-(im-im2);
SE1=strel('square',4) ;
%using a small filter to mask the img
out1=imerode(I2,SE1) ;
mask2 = ( out1(:,:,1) <=1)&...
    (out1(:,:,2) <=1) & (out1(:,:,3)<=1);

im3 = I;

%edging before filling the mask
mask3 = edge(mask2,'Prewitt');
mask2(mask3==1)=1;



mask2 = imfill(mask2,'holes');
mask3 =  bwareafilt(mask2,[0 ,imgSize]); 
%to scale based on size of img
mask2 = mask2-mask3;


mask2 = uint8(mask2);

im3(:,:,1)=im3(:,:,1).*mask2; 
im3(:,:,2)=im3(:,:,2).*mask2; 
im3(:,:,3)=im3(:,:,3).*mask2; 

SE2=strel('square',2) ;
im3 = imerode(im3,SE2);



%fixing noise
mask2(im3(:,:,1)- im3(:,:,3) <=15 & im3(:,:,1)- im3(:,:,2)<=15)  = 0;
[labeledImage, numberOf] = bwlabel(mask2);
blobMeasurements = regionprops(labeledImage, 'Area');
area  = [blobMeasurements.Area];
for blob = 1: numberOf
        if area(blob) < 10 %clearing noise
            mask2 (labeledImage == blob) =0;
        end
end

%applying final mask
im3(:,:,1)=im3(:,:,1).*mask2; 
im3(:,:,2)=im3(:,:,2).*mask2; 
im3(:,:,3)=im3(:,:,3).*mask2; 

figure(1);
imshowpair(I,im3,'montage');
impixelinfo();


end

