function AuthToken = aquariusGetAuthToken(Host, Username, Password)

if ~exist('Username','var') || isempty(Username)
    [Username,Password] = logindlg('Title','Aquarius Login');
elseif ~exist('Password','var') || isempty(Username)
    Password = logindlg('Title',sprintf('Aquarius Password for username = %s',Username),'Password','only');
end

%% make the POST request
AquariusURL = ['http://',Host,'/AQUARIUS/Publish/AquariusPublishRestService.svc/'];
AuthToken = webread([AquariusURL,'getAuthToken?user=', Username, ...
                     '&encPwd=', Password]);

end