function [beta] = LLC_pooling(integralData, imageInfo, x, y, patchSize, pyramidLevels)

pyramid = 2.^(0:pyramidLevels);
stepSize.x = patchSize.x/(pyramid(end));
stepSize.y = patchSize.y/(pyramid(end));

pyramidIdx = cell(pyramid(end));
tBins = sum(pyramid.^2);
featureSize = size(integralData{1}, 2);
numImages = length(integralData);
beta = zeros(numImages, featureSize*tBins);
currentBin = 1;

for i=1:pyramid(end)
    start_x = x+(i-1)*stepSize.x;
    end_x = x+i*stepSize.x;
    x_idx = cellfun(@(x) getIdxX(x, start_x, end_x), imageInfo, 'UniformOutput', false);
    
    for j=1:pyramid(end)
        start_y = y + (j-1)*stepSize.y;
        end_y = y + j*stepSize.y;
        idx = cellfun(@(x, y) getIdxY(x, y,start_y, end_y), imageInfo, x_idx, 'UniformOutput', false);
        binIdx = (currentBin-1)*featureSize+1:currentBin*featureSize; 
        pyramidIdx{i, j} = binIdx;
        try
            beta(:, binIdx) = cell2mat(cellfun(@maxIdxPascal, integralData, idx, 'UniformOutput', false));
        catch
            fprintf('Tinghui error: j = %d\n', j);
            temp = cellfun(@maxIdxPascal, integralData, idx, 'UniformOutput', false);
            emp_idx = cellfun(@isempty, temp);
            emp_idx = find(emp_idx);
            for t = 1 : length(temp)
                if ~isempty(temp{t})
                    sample_cell = temp{t};
                    break;
                end
            end
            for e = 1 : numel(emp_idx)
                temp{emp_idx(e)} = sparse(zeros(size(sample_cell)));
            end
            beta(:, binIdx) = cell2mat(temp);
        end
        currentBin = currentBin + 1;
    end
end

pyramidCell = cell(length(pyramid));
pyramidCell{1} = pyramidIdx;
for i=1:length(pyramid)-1
    pyramidSize = pyramid(end-i);
    pyramidCell{i+1} = cell(pyramidSize);
    for j=1:pyramidSize
        for k=1:pyramidSize
            binIdx = (currentBin-1)*featureSize+1:currentBin*featureSize;
            pyramidCell{i+1}{j, k} = binIdx;
            beta(:, binIdx) = max(beta(:, pyramidCell{i}{2*(j-1)+1, 2*(k-1)+1}), beta(:, pyramidCell{i}{2*(j-1)+1, 2*k}));
            beta(:, binIdx) = max(beta(:, pyramidCell{i}{2*j, 2*(k-1)+1}), beta(:, binIdx));
            beta(:, binIdx) = max(beta(:, pyramidCell{i}{2*j, 2*k}), beta(:, binIdx));            
            currentBin = currentBin + 1;
        end
    end
end

norm_beta = sqrt(sum(beta.^2, 2));
beta = beta./repmat(norm_beta, [1 size(beta, 2)]);
