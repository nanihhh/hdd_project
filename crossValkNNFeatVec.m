function [crossValAvg,crossValSD] = crossValkNNFeatVec(savefile)
% Test the classification algorithm following the ideas of Section 6 of
% Dr. Meyer's project guide.
%
% This uses matlab's built-in kNN routines

if nargin == 0
   %savefile = 'featVecsWCH.mat';
   savefile = 'featVecsDale.mat';
end 

load(savefile);
dataDir = getDir();
[wavList,genre] = textread([dataDir,'ground_truth.csv'],'%s %s','delimiter',',');
nSongs = length(wavList);
genre   = strrep(genre, '"', '');
genreValues = getGenres(genre); 

% Standardize feature vectors
mu = repmat(mean(feat, 2), [1 size(feat,2)]);
vars = repmat(var(feat, 0, 2), [1 size(feat,2)]);
feat = (feat - mu)./vars;
fprintf(1,'Feature vectors standardized\n');

% Begin cross validation
R = cell(10,5); 
for n =1: 10
   fprintf(1,'\rn = %d',n);
   G = cell(6,5); 
   for i =1:6
      dum = find(genreValues ==i); 
      pos = randperm(length(dum));
      for l = 1:5
         if l ==5
            G{i,l} = dum(pos(1+floor((l-1)*length(dum)/5): end))'; 
         else
            G{i,l} = dum(pos(1+floor((l-1)*length(dum)/5): floor((l)*length(dum)/5)))'; 
         end
      end
   end

   for k = 1:5
      testIndex = [ G{1,k},G{2,k},G{3,k},G{4,k},G{5,k},G{6,k}] ; 
      trainIndex =setdiff([1:nSongs], unique(testIndex)); 
      genreTest = genreValues(testIndex);
      genreTrain = genreValues(trainIndex); 

      % train kNN classifier for this subset
      mdl = fitcknn(transpose(feat(:,trainIndex)),genreTrain,...
         'NumNeighbors',5,'Distance','seuclidean');

      % make predictions
      confMat = zeros(numel(unique(genreValues))); % 6x6
      for j=1:length(testIndex)
         trueGenre = genreTest(j);
         predGenre = predict(mdl, transpose(feat(:,testIndex(j))));
         %predGenre = randi([1 6]); % random prediction ~ 17% correct
         confMat(predGenre, trueGenre) = confMat(predGenre, trueGenre) + 1;
      end
      R{n,k} = confMat; 

   end

end
fprintf(1,'\n');
crossValAvg = zeros(6,6); 
crossValSD = zeros(6,6); 

% compute mean and std dev of confusion matrixes
for i =1:6
   for j =1:6

      crossValAvg(i,j)  = round(mean([R{1,1}(i,j),R{1,2}(i,j),R{1,3}(i,j),R{1,4}(i,j),R{1,5}(i,j),...
      R{2,1}(i,j),R{2,2}(i,j),R{2,3}(i,j),R{2,4}(i,j),R{2,5}(i,j),...
      R{3,1}(i,j),R{3,2}(i,j),R{3,3}(i,j),R{3,4}(i,j),R{3,5}(i,j),...
      R{4,1}(i,j),R{4,2}(i,j),R{4,3}(i,j),R{4,4}(i,j),R{4,5}(i,j),...
      R{5,1}(i,j),R{5,2}(i,j),R{5,3}(i,j),R{5,4}(i,j),R{5,5}(i,j),...
      R{6,1}(i,j),R{6,2}(i,j),R{6,3}(i,j),R{6,4}(i,j),R{6,5}(i,j),...
      R{7,1}(i,j),R{7,2}(i,j),R{7,3}(i,j),R{7,4}(i,j),R{7,5}(i,j),...
      R{8,1}(i,j),R{8,2}(i,j),R{8,3}(i,j),R{8,4}(i,j),R{8,5}(i,j),...
      R{9,1}(i,j),R{9,2}(i,j),R{9,3}(i,j),R{9,4}(i,j),R{9,5}(i,j),...
      R{10,1}(i,j),R{10,2}(i,j),R{10,3}(i,j),R{10,4}(i,j),R{10,5}(i,j)]));

      crossValSD(i,j) = std([R{1,1}(i,j),R{1,2}(i,j),R{1,3}(i,j),R{1,4}(i,j),R{1,5}(i,j),...
      R{2,1}(i,j),R{2,2}(i,j),R{2,3}(i,j),R{2,4}(i,j),R{2,5}(i,j),...
      R{3,1}(i,j),R{3,2}(i,j),R{3,3}(i,j),R{3,4}(i,j),R{3,5}(i,j),...
      R{4,1}(i,j),R{4,2}(i,j),R{4,3}(i,j),R{4,4}(i,j),R{4,5}(i,j),...
      R{5,1}(i,j),R{5,2}(i,j),R{5,3}(i,j),R{5,4}(i,j),R{5,5}(i,j),...
      R{6,1}(i,j),R{6,2}(i,j),R{6,3}(i,j),R{6,4}(i,j),R{6,5}(i,j),...
      R{7,1}(i,j),R{7,2}(i,j),R{7,3}(i,j),R{7,4}(i,j),R{7,5}(i,j),...
      R{8,1}(i,j),R{8,2}(i,j),R{8,3}(i,j),R{8,4}(i,j),R{8,5}(i,j),...
      R{9,1}(i,j),R{9,2}(i,j),R{9,3}(i,j),R{9,4}(i,j),R{9,5}(i,j),...
      R{10,1}(i,j),R{10,2}(i,j),R{10,3}(i,j),R{10,4}(i,j),R{10,5}(i,j)]);                        
end
end
probCorrect = sum(diag(crossValAvg))/sum(sum(sum(crossValAvg)))
latexTable(crossValAvg, 'crossValAvg.tex', '%i', unique(genre));
latexTable(crossValSD, 'crossValSD.tex', '%3.2f', unique(genre));

correctClassRate = zeros([6 1]);
for i=1:6
   correctClassRate(i) = crossValAvg(i,i)/sum(crossValAvg(:,i));
end

correctClassRate

end

function [g, code] = getGenres(genres)
% return a vector of numbers representing the genre of each song in 
% the input genres cell array (entries are strings of genre name)
% optional output is the coding scheme

genreNames = unique(genres);

codeCmd = 'code = struct(';
for i=1:numel(genreNames)-1
      codeCmd = strcat(codeCmd, '''', genreNames{i},''',', sprintf('%d,', i));
   end
   i = numel(genreNames);
   codeCmd = strcat(codeCmd, '''', genreNames{i},''',', sprintf('%d);', i));
   eval(codeCmd);
   %code

   g = zeros([size(genres,1) 1]);
   for i=1:size(genres,1);
      for genreInd=1:numel(genreNames)
         if strcmp(genres{i}, genreNames{genreInd})
            g(i) = getfield(code, genreNames{genreInd});
            break
         end
      end
   end

end % getGenres
