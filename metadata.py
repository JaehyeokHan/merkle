import os
import datetime, time

path = 'C:\\Users\\Jack\\Documents\\GitHub\\merkle\\test_samples\\govdocs1\\001\\001961.pdf'

def Filemetadata_dict(target) :
    if os.path.exists(target) == False:
        exit(1)
    else:
        if os.path.isabs(target) == False:
            Dir = os.path.abspath(target)
        newFileInfo = []

        # Parent directory
        parent = os.path.dirname(target)
        newFileInfo.append(parent)

        # Entry name
        name = os.path.split(target)
        if name[0] == parent:
            filename = name[1]
            newFileInfo.append(filename)
        else:
            print(name[0], parent)

        # timestamps
        ctime = os.path.getctime(target)
        mtime = os.path.getmtime(target)
        atime = os.path.getatime(target)
        newFileInfo.append( str(datetime.datetime.fromtimestamp(ctime)) )
        newFileInfo.append( str(datetime.datetime.fromtimestamp(ctime)) )
        newFileInfo.append( str(datetime.datetime.fromtimestamp(ctime)) )

        # size
        size = os.path.getsize(target)
        newFileInfo.append(size)

    # Input values(file metadata) into the dictionary data type
    file_metadata = dict(zip(['parent', 'filename', 'ctime', 'mtime', 'atime', 'size'], newFileInfo))
    return file_metadata

print(Filemetadata_dict(path))
