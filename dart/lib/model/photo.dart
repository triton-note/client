library photo;

class Photo {
  Image original;
  Image mainview;
  Image thumbnail;
  
  Photo(this.original, this.mainview, this.thumbnail);
}

class Image {
  String path;
  
  Image(this.path);
}
