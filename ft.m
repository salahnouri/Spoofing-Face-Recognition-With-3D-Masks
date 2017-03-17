file = 'E:\Marco\drive\3DMask\train\real\01_01_01.hdf5';
%% load the video
rgb = hdf5read(file, 'Color_Data');

%% rotate the video
rgb = permute(rgb, [2 1 3 4]);
    
    % Create a cascade detector object.
faceDetector = vision.CascadeObjectDetector();

% Read a video frame and run the face detector.
videoFrame = rgb(:,:,:,1);
bbox       = step(faceDetector, videoFrame);

% Draw the returned bounding box around the detected face.
videoFrame = insertShape(videoFrame, 'Rectangle', bbox);
% figure; imshow(videoFrame); title('Detected face');

% Convert the first box into a list of 4 points
% This is needed to be able to visualize the rotation of the object.
bboxPoints = bbox2points(bbox(1, :));

%%
% Detect feature points in the face region.
points = detectMinEigenFeatures(rgb2gray(videoFrame), 'ROI', bbox);

% Display the detected points.
% figure, imshow(videoFrame), hold on, title('Detected features');
% plot(points);

%%
% Create a point tracker and enable the bidirectional error constraint to
% make it more robust in the presence of noise and clutter.
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

% Initialize the tracker with the initial point locations and the initial
% video frame.
points = points.Location;
initialize(pointTracker, points, videoFrame);

%%
videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame, 2), size(videoFrame, 1)]+30]);

%%
% Make a copy of the points to be used for computing the geometric
% transformation between the points in the previous and the current frames
oldPoints = points;
srgb=size(rgb);

fileID = fopen('f_names.txt','w');
for i = 1:srgb(4)
    % get the next frame
    videoFrame = rgb(:,:,:,i);

    % Track the points. Note that some points may be lost.
    [points, isFound] = step(pointTracker, videoFrame);
    visiblePoints = points(isFound, :);
    oldInliers = oldPoints(isFound, :);

    if size(visiblePoints, 1) >= 2 % need at least 2 points

        % Estimate the geometric transformation between the old points
        % and the new points and eliminate outliers
        [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
            oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);

        % Apply the transformation to the bounding box points
        bboxPoints = transformPointsForward(xform, bboxPoints);

        % Insert a bounding box around the object being tracked
%         bboxPolygon = reshape(bboxPoints', 1, []);
%         videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, ...
%             'LineWidth', 2);

        % Display tracked points
%         videoFrame = insertMarker(videoFrame, visiblePoints, '+', ...
%             'Color', 'white');

        % Reset the points
        oldPoints = visiblePoints;
        setPoints(pointTracker, oldPoints);
        angle = rad2deg(atan((bboxPoints(4,2)-bboxPoints(3,2))/(bboxPoints(4,1)-bboxPoints(3,1))));
        videoFrame = imrotate(videoFrame,angle,'crop');
        bbox = [bboxPoints(1,1), bboxPoints(1,2), bboxPoints(3,1)-bboxPoints(4,1), bboxPoints(4,2)-bboxPoints(1,2)];
        videoFrame = imcrop(videoFrame,bbox);
        videoFrame = imresize(videoFrame, [128 128]);
        s = 'face/f';
        s = strcat(s,int2str(i));
        s = strcat(s,'.bmp');
        imwrite(videoFrame,s);
        fprintf(fileID,'%s ',s);
    end

    % Display the annotated video frame using the video player object
%     step(videoPlayer, videoFrame);
end
fclose(fileID);

% Clean up
release(videoPlayer);
release(pointTracker);













