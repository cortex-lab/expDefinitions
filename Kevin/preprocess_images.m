fldr_in = 'C:\Users\Kevin\Documents\Fruits';
fldr_out = 'X:\pregenerated_textures\Kevin';
fldrdir = dir(fldr_in);
fldrdir(1:2) = [];

tic
for img_i = 1:length(fldrdir)
    
    % Load the image
    img_in = imread(fullfile(fldr, fldrdir(img_i).name));
    
    % Greyscale the image
    if size(img_in,3) == 3
        img_grey = rgb2gray(img_in);
    else
        img_grey = img_in;
    end
    [ysize, xsize] = size(img_grey);
    
    if xsize > ysize
        to_trim = (xsize - ysize) / 2;
        img_crop = img_grey(:,to_trim:(end - to_trim));
    elseif ysize > xsize
        to_trim = (ysize - xsize) / 2;
        img_crop = img_grey(to_trim:(end - to_trim), :);
    else
        img_crop = img_grey;
    end
    
    img_resize = imresize(img_crop,[250, 250]);
    img_z = zscore(single(img_resize));
    
    img_255 = ( 1 + 253 * (img_z - min(img_z(:))) / (max(img_z(:)) - min(img_z(:))));
    img = uint8( 100 * img_255 / mean(img_255(:)));
    save(fullfile(fldr_out, ['img', num2str(img_i)]), 'img');
    
end
toc