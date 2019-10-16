 fldr_out = 'X:\pregenerated_textures\Kevin\simple_shapes';
 mkdir(fldr_out)
%% Create distinguishable shapes
% Must be 250 by 250 pixels
% PTB background luminence is 127
grey = 127;
normalize_brightness = @(img, b) uint8( b * single(img) / mean(single(img(:))));
b = 100;

% Frame Square, dark on light
fs = 36;
frame_square = 0*ones(250, 250);
frame_square(1:fs,:) = grey;
frame_square((end-fs):end,:) = grey;
frame_square(:,1:fs) = grey;
frame_square(:,(end-fs):end) = grey;
%frame_square = normalize_brightness(frame_square, b);
% Frame Square, dark on light
frame_square2 = grey*ones(250, 250);
frame_square2(1:fs,:) = 0;
frame_square2((end-fs):end,:) = 0;
frame_square2(:,1:fs) = 0;
frame_square2(:,(end-fs):end) = 0;
%frame_square2 = normalize_brightness(frame_square2, b);
% X, dark on light
lw = 50;
x = grey*ones(250, 250+lw);
for row_i = 1:250
    x(row_i,row_i:row_i+lw) = 0;
    x((end-row_i+1),row_i:row_i+lw) = 0;
end
x = x(1:250, lw/2 : (249+lw/2));
%x = normalize_brightness(x, b);
% X, light on dark
x2 = 0*ones(250, 250+lw);
for row_i = 1:250
    x2(row_i,row_i:row_i+lw) = grey;
    x2((end-row_i+1),row_i:row_i+lw) = grey;
end
x2 = x2(1:250, lw/2 : (249+lw/2));
%x2 = normalize_brightness(x2, b);
% Plus
lw = 36;
plus = grey*ones(250, 250);
plus(125-lw/2:125+lw/2,:) = 25;
plus(:,125-lw/2:125+lw/2) = 25;

lw = 36;
plus2 = 0*ones(250, 250);
plus2(125-lw/2:125+lw/2,:) = grey;
plus2(:,125-lw/2:125+lw/2) = grey;

% Circle
xs = repmat(1:250, [250,1]);
ys = repmat((1:250)', [1, 250]);
rad = sqrt(((xs-125).^2 + (ys - 125).^2));

circle = grey*ones(250, 250);
circle(rad < 75) = 25;
%circle = normalize_brightness(circle, b);
% Frame Circle
circle2 = grey*ones(250, 250);
circle2(rad < 100 & rad > 64) = 25;
%circle2 = normalize_brightness(circle2, b);

% Bar
lw = 72;
hbar = grey*ones(250, 250);
hbar(125-lw/2:125+lw/2,:) = 25;
%hbar = normalize_brightness(hbar, b);

vbar = grey*ones(250, 250);
vbar(:,125-lw/2:125+lw/2) = 25;
%vbar = normalize_brightness(vbar, b);

% Triangle
tri = grey*ones(250, 250);
inds = 2*abs(xs-125) < ys-50 ...
    & ys < 200;
tri(inds) = 25;
%tri = normalize_brightness(tri, b);

%% View the images, make sure they look good
imgs = {frame_square, frame_square2, x, x2, plus, plus2, circle, circle2, hbar, vbar, tri};

figure;
for img_i = 1:length(imgs)
    img = imgs{img_i};
    imshow(img, [0, 255])
    saveas(gcf,[fldr_out,'\Images\img_', num2str(img_i)],'png');
    save(fullfile(fldr_out, ['img', num2str(img_i)]), 'img');
end
