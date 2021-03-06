function  [out, msk_img] = grey_world_fg_bg(inp,dbRGB, plt)
%function  [out, msk_img, fg_img] = grey_world_fg_bg(inp,dbRGB, plt)
% inp: input RGB image filename or 3D matrix of RGB image channels
% dbRGB: reference R, G, B average values for bg and fg. A vector of 6
% uint8 values. E.g.[245,245,245,148,148,178]
% plt=1 enables plots, default is
%

% Copyright 2008-2013 F. Boray Tek.
% All rights reserved.
%
%
% Permission granted to use and copy the code for research and 
% educational purposes only.  Sale of the code is not permitted. The code may be 
% redistributed so long as the original source and authors are cited.
% Please ask for up to date citation information.

if(nargin<2)
    disp('must give at least input filename and RGB reference values');
    disp('this will run in demo mode!');

    [out, msk_img] = grey_world_fg_bg('ex1.jpg',[245,245,245,148,148,178], 1);
    [out, msk_img] = grey_world_fg_bg('ex2.jpg',[245,245,245,148,148,178], 1);
    [out, msk_img] = grey_world_fg_bg('ex3.jpg',[245,245,245,148,148,178], 1);
    return;
elseif (nargin==2)
    plt = 0; 
end
    
if (ischar(inp)) 
    img_rgb = imread (inp);
else
    img_rgb = inp; 
end




ref_mn_bg_red = dbRGB(1);
ref_mn_bg_green = dbRGB(2);
ref_mn_bg_blue = dbRGB(3); 
ref_mn_fg_red = dbRGB(4);
ref_mn_fg_green = dbRGB(5);
ref_mn_fg_blue = dbRGB(6); 

%if(nargin ==1)
img_gray =uint8(rgb2gray(img_rgb)); 
img_rgb = double(img_rgb);

%This one uses the simplest Otsu thresholding. 
%Because area based double threshold requires compilation of mex files
%that implement area opening function
img_gray_inv = 255-img_gray;
level = graythresh(double(img_gray_inv)/255);
msk_img = im2bw(img_gray_inv,level);

%%
bg_px=zero_background_infunc(img_rgb,~msk_img);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% calculate image bg ground mean 
bg_px_gray = rgb2gray(bg_px); 

%%%%%%%%%%%%%%%%%%%%%%%%%%% find non zeros and vectorize 
I_bg_px = find( bg_px_gray ~= 0 ) ;   

r_bg_inp =double( bg_px(:,:,1));   
r_inp_bg_v = r_bg_inp(I_bg_px);
g_bg_inp =double( bg_px(:,:,2));   
g_inp_bg_v = g_bg_inp(I_bg_px);
b_bg_inp =double( bg_px(:,:,3));   
b_inp_bg_v = b_bg_inp(I_bg_px);

mn_bg_red = mean(r_inp_bg_v);
mn_bg_green = mean(g_inp_bg_v);
mn_bg_blue = mean(b_inp_bg_v);

% normalize for background
new_r = img_rgb(:,:,1) / mn_bg_red*255;
new_g = img_rgb(:,:,2) / mn_bg_green*255;
new_b = img_rgb(:,:,3) / mn_bg_blue*255;

ratios_bg = [ 255/mn_bg_red, 255/mn_bg_green, 255/mn_bg_blue]; 

new_rgb(:,:,1) = new_r;
new_rgb(:,:,2) = new_g;
new_rgb(:,:,3) = new_b; 

% now background is saturated and normalized 
out =  uint8(new_rgb);

%%
if (plt)
    figure(111); 
    in_r = img_rgb(:,:,1);
    in_g = img_rgb(:,:,2);
    in_b = img_rgb(:,:,3);
    h_r_inp = histc ( in_r(:), 0.5:1:255);
    h_g_inp = histc ( in_g(:), 0.5:1:255);
    h_b_inp = histc ( in_b(:), 0.5:1:255);
    subplot(321); 
    x= 1:255; 
    plot( x, h_r_inp, 'r', x, h_g_inp, 'g', x, h_b_inp, 'b');
    title ('Input RGB histograms');

    h_r_inp_bg_v = histc ( r_inp_bg_v, 0.5:1:255);
    h_g_inp_bg_v = histc ( g_inp_bg_v, 0.5:1:255);
    h_b_inp_bg_v = histc ( b_inp_bg_v, 0.5:1:255);
    subplot(322);
    x= 1:255; 
    plot( x, h_r_inp_bg_v, 'r', x, h_g_inp_bg_v, 'g', x, h_b_inp_bg_v, 'b');
    title ('Input Background RGB histograms');
    h_r_out_bg_v = histc ( new_r(:), 0.5:1:255);
    h_g_out_bg_v = histc ( new_g(:), 0.5:1:255);
    h_b_out_bg_v = histc ( new_b(:), 0.5:1:255);
    subplot(323);
    plot( x, h_r_out_bg_v, 'r.', x, h_g_out_bg_v, 'g.', x, h_b_out_bg_v, 'b.');
    title ('I Background/ mean background  RGB histograms');
    
end

%% now the foreground starts 

img_gray =rgb2gray( new_rgb); 

obj_px=zero_background_infunc(new_rgb,msk_img);
bg_px=zero_background_infunc(new_rgb,~msk_img);

fg_px_gray = rgb2gray( obj_px); 
    
I_fg_px = find( fg_px_gray ~= 0 ) ; 
    
r_fg_inp =double( obj_px(:,:,1));   r_inp_fg_v = r_fg_inp(I_fg_px);
g_fg_inp =double( obj_px(:,:,2));   g_inp_fg_v = g_fg_inp(I_fg_px);
b_fg_inp =double( obj_px(:,:,3));   b_inp_fg_v = b_fg_inp(I_fg_px);
    
    
mn_fg_red  = mean(r_inp_fg_v);
mn_fg_green= mean(g_inp_fg_v);
mn_fg_blue = mean(b_inp_fg_v);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%MEAN REFERENCE
 mn_ref_fg_red    = (ref_mn_fg_red / ref_mn_bg_red*255); 
 mn_ref_fg_green = (ref_mn_fg_green /ref_mn_bg_green*255); 
 mn_ref_fg_blue  = (ref_mn_fg_blue /ref_mn_bg_blue*255);

 
m1 = mn_fg_red / mn_ref_fg_red;
m2 = mn_fg_green / mn_ref_fg_green;
m3 = mn_fg_blue / mn_ref_fg_blue    ;

%%%% M FOR MAX 
r_fg_inp =double(obj_px(:,:,1))/m1;   
g_fg_inp =double(obj_px(:,:,2))/m2;   
b_fg_inp =double(obj_px(:,:,3))/m3;   



ratios_fg = [1/m1, 1/m2, 1/m3];

 
new_fg_rgb(:,:,1) = r_fg_inp;
new_fg_rgb(:,:,2) = g_fg_inp;
new_fg_rgb(:,:,3) = b_fg_inp; 

new_rgb = (new_fg_rgb +bg_px);

out =  double(new_rgb);

%%
ite = 0 ;
% this part can be used to iterate
% while ((any(ratios_fg<0.95) | any(ratios_fg>1.05)) & ite < 4)
%     r_inp_fg_v = r_fg_inp(I_fg_px);
%     g_inp_fg_v = g_fg_inp(I_fg_px);
%     b_inp_fg_v = b_fg_inp(I_fg_px);
%     
%     mn_fg_red  = mean(r_inp_fg_v);
%     mn_fg_green= mean(g_inp_fg_v);
%     mn_fg_blue = mean(b_inp_fg_v);
%     
% 
%     m1 = mn_fg_red /mn_ref_fg_red
%     m2 = mn_fg_green / mn_ref_fg_green
%     m3 = mn_fg_blue / mn_ref_fg_blue     %put a bias for contrast enhancement
%     
%     ratios_fg = [m1, m2, m3];
%     r_fg_inp =double(obj_px(:,:,1))/m1;   
%     g_fg_inp =double(obj_px(:,:,2))/m2;   
%     b_fg_inp =double(obj_px(:,:,3))/m3;   
%     
%     ite = ite+1
% end
%% plt histograms

if (plt) 

    h_r_inp_fg_v = medfilt1(histc ( r_inp_fg_v, 0.5:1:255),7);
    h_g_inp_fg_v = medfilt1(histc ( g_inp_fg_v, 0.5:1:255),7);
    h_b_inp_fg_v = medfilt1(histc ( b_inp_fg_v, 0.5:1:255),13);
    
   subplot(324);
    x= 1:255; 
    plot( x, h_r_inp_fg_v, 'r', x, h_g_inp_fg_v, 'g', x, h_b_inp_fg_v, 'b');
    xlabel('Level');    ylabel('Pixel Count');
    xlim([1 260]); %ylim([0 25000]);

    title ('Foreground^~ RGB histograms');
    h_r_out_fg_v = medfilt1(histc ( r_fg_inp(:), 0.5:1:255),7);
    h_g_out_fg_v = medfilt1(histc ( g_fg_inp(:), 0.5:1:255),7);
    h_b_out_fg_v = medfilt1(histc ( b_fg_inp(:), 0.5:1:255),7);
    
    subplot(325);
    plot( x, h_r_out_fg_v, 'r', x, h_g_out_fg_v, 'g', x, h_b_out_fg_v, 'b');
    title ('Foreground /ref  RGB histograms');
    xlabel('Level');    ylabel('Pixel Count');
    xlim([1 260]); %ylim([0 25000]);
    
    out_r = out(:,:,1);
    out_g = out(:,:,2);
    out_b = out(:,:,3);
    h_r_out = histc ( out_r(:), 0.5:1:256);
    h_g_out = histc ( out_g(:), 0.5:1:256);
    h_b_out = histc ( out_b(:), 0.5:1:256);

    subplot(326);
    x= 0:255; 
    plot( x, h_r_out, 'r', x, h_g_out, 'g', x, h_b_out, 'b');
    title ('Output RGB histograms');
    xlabel('Level');    ylabel('Pixel Count');
    xlim([1 260]); %ylim([0 25000]);

    figure; 
    subplot(121);
    imagesc(uint8(img_rgb));
    subplot(122);
    imagesc(uint8(out));

    
end




end

function dg=zero_background_infunc(dg,dc)
dg(:,:,1)=uint8(double(dg(:,:,1)).*(double(dc>0)));
if ndims(dg)>2
    dg(:,:,2)=uint8(double(dg(:,:,2)).*(double(dc)>0));
    dg(:,:,3)=uint8(double(dg(:,:,3)).*(double(dc)>0));
end
end
