%% Example of accessing Aquarius via RESTfull web services
%
% Demonstrates usage of:
%
% open <a href="matlab:open AquariusExample">AquariusExample</a> to see example code
%
% See also: 

%% Set Username/password and check logon
Host = 'aquarius.niwa.co.nz';

% Get Authtoken (request username/password from user)
AuthToken = aquariusGetAuthToken(Host);

% Check logon works
assert(~isempty(AuthToken),'Logon failed')

fprintf('Your username/password is valid for http://%s/AQUARIUS/Publish/AquariusPublishRestService.svc\n', ...
        Host)

%% Get a list of locations available
LocationFilter='LocationName=*Hurunui*';
LocationTable = aquariusGetLocations(Host, LocationFilter, AuthToken);

%% Get a list of datasets for a specified site
SiteId = 65119;
DatasetTable = aquariusListDatasets(Host, SiteId, AuthToken);

%% Get some data
DataId = 'HG.Master';
FromDate = datetime(2015,7,1);
ToDate = datetime(2016,9,1);
DataTable = aquariusGetData(Host, SiteId, DataId, FromDate, ToDate, AuthToken);

% plot
plot(DataTable.Time, DataTable.Value);




