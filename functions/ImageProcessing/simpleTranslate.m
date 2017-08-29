function B = simpleTranslate(A, Translation, FillValue)
%SIMPLETRANSLATE Translate image.
%   B = SIMPLETRANSLATE(A,TRANSLATION) translates image A by a translation
%   vector TRANSLATION. TRANSLATION is of the form [TX TY].

FillLeft = FillValue * ones(size(A,1),max(Translation(1),0),size(A,3));
FillRight = FillValue * ones(size(A,1),max(-Translation(1),0),size(A,3));
FillTop = FillValue * ones(max(-Translation(2),0), ...
                           size(A,2)-abs(Translation(1)),size(A,3));
FillBottom = FillValue * ones(max(Translation(2),0), ...
                              size(A,2)-abs(Translation(1)),size(A,3));

ACrop = A(1+max(Translation(2),0):end-max(-Translation(2),0), ...
          1+max(-Translation(1),0):end-max(Translation(1),0));

B = [FillLeft,[FillTop;ACrop;FillBottom],FillRight];

end

