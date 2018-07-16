function props = OCTFileGetProperties( handle )

props = xml2struct(fullfile(handle.path, 'Header.xml'));
props = props.Ocity;
end