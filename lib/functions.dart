String removeFileNameFromPath(String path) => path.substring(0, path.lastIndexOf('\\'));

String getFileNameFromPath(String path) => path.substring(path.lastIndexOf('\\') + 1);