package com.mapswithme.maps.bookmarks.data;

import android.content.res.Resources;
import android.os.Parcel;
import android.os.Parcelable;
import android.text.TextUtils;

import com.mapswithme.maps.Framework;
import com.mapswithme.maps.R;

public abstract class MapObject implements Parcelable
{
  protected String mName;
  protected double mLat;
  protected double mLon;
  protected String mTypeName;
  protected Metadata mMetadata;

  public MapObject(String name, double lat, double lon, String typeName)
  {
    mName = name;
    mLat = lat;
    mLon = lon;
    mTypeName = typeName;
    mMetadata = new Metadata();
  }

  public void setDefaultIfEmpty(Resources res)
  {
    if (TextUtils.isEmpty(mName))
      mName = TextUtils.isEmpty(mTypeName) ? res.getString(R.string.dropped_pin) : mTypeName;

    if (TextUtils.isEmpty(mTypeName))
      mTypeName = res.getString(R.string.placepage_unsorted);
  }

  @Override
  public int hashCode()
  {
    final int prime = 31;
    int result = 1;
    long temp;
    temp = Double.doubleToLongBits(mLat);
    result = prime * result + (int) (temp ^ (temp >>> 32));
    temp = Double.doubleToLongBits(mLon);
    result = prime * result + (int) (temp ^ (temp >>> 32));
    result = prime * result + ((mName == null) ? 0 : mName.hashCode());
    result = prime * result + ((mTypeName == null) ? 0 : mTypeName.hashCode());
    return result;
  }

  @Override
  public boolean equals(Object obj)
  {
    if (this == obj)
      return true;
    if (obj == null ||
        getClass() != obj.getClass())
      return false;

    final MapObject other = (MapObject) obj;
    return Double.doubleToLongBits(mLon) == Double.doubleToLongBits(other.mLon) &&
        Double.doubleToLongBits(mLat) == Double.doubleToLongBits(other.mLat) &&
        TextUtils.equals(mName, other.mName) &&
        TextUtils.equals(mTypeName, other.mTypeName);
  }

  public double getScale() { return 0; }

  public String getName() { return mName; }

  public double getLat() { return mLat; }

  public double getLon() { return mLon; }

  public void setLat(double lat)
  {
    mLat = lat;
  }

  public void setLon(double lon)
  {
    mLon = lon;
  }

  public String getPoiTypeName() { return mTypeName; }

  public void addMetadata(int type, String value)
  {
    mMetadata.addMetadata(type, value);
  }

  public void addMetadata(int[] types, String[] values)
  {
    for (int i = 0; i < types.length; i++)
      addMetadata(types[i], values[i]);
  }

  public String getMetadata(Metadata.MetadataType type)
  {
    return mMetadata.getMetadata(type);
  }

  public abstract MapObjectType getType();

  @Override
  public int describeContents()
  {
    return 0;
  }

  @Override
  public void writeToParcel(Parcel dest, int flags)
  {
    dest.writeString(getType().toString());
    dest.writeString(mName);
    dest.writeDouble(mLat);
    dest.writeDouble(mLon);
    dest.writeString(mTypeName);
    dest.writeParcelable(mMetadata, 0);
  }

  public static final Creator<MapObject> CREATOR = new Creator<MapObject>()
  {
    @Override
    public MapObject createFromParcel(Parcel source)
    {
      return readFromParcel(source);
    }

    @Override
    public MapObject[] newArray(int size)
    {
      return new MapObject[size];
    }
  };

  protected static MapObject readFromParcel(Parcel source)
  {
    final MapObjectType type = MapObjectType.valueOf(source.readString());
    switch (type)
    {
    case POI:
      return new Poi(source);
    case ADDITIONAL_LAYER:
      return new SearchResult(source);
    case MY_POSITION:
      return new MyPosition(source);
    case API_POINT:
      return new ApiPoint(source);
    case BOOKMARK:
      return new Bookmark(source);
    }
    return null;
  }

  protected MapObject(Parcel source)
  {
    mName = source.readString();
    mLat = source.readDouble();
    mLon = source.readDouble();
    mTypeName = source.readString();
    mMetadata = source.readParcelable(Metadata.class.getClassLoader());
  }

  public enum MapObjectType
  {
    POI,
    API_POINT,
    BOOKMARK,
    MY_POSITION,
    ADDITIONAL_LAYER
  }

  public static class Poi extends MapObject
  {
    public Poi(String name, double lat, double lon, String typeName)
    {
      super(name, lat, lon, typeName);
    }

    protected Poi(Parcel source)
    {
      super(source);
    }

    @Override
    public MapObjectType getType()
    {
      return MapObjectType.POI;
    }
  }

  public static class SearchResult extends MapObject
  {
    public SearchResult(long index)
    {
      super("", 0, 0, "");
      Framework.injectData(this, index);
    }

    public SearchResult(String name, String type, double lat, double lon)
    {
      super(name, lat, lon, type);
    }

    protected SearchResult(Parcel source)
    {
      super(source);
    }

    @Override
    public MapObjectType getType()
    {
      return MapObjectType.ADDITIONAL_LAYER;
    }
  }

  public static class ApiPoint extends MapObject
  {
    private final String mId;

    public ApiPoint(String name, String id, String poiType, double lat, double lon)
    {
      super(name, lat, lon, poiType);
      mId = id;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags)
    {
      super.writeToParcel(dest, flags);
      dest.writeString(mId);
    }

    protected ApiPoint(Parcel source)
    {
      super(source);
      mId = source.readString();
    }

    @Override
    public MapObjectType getType()
    {
      return MapObjectType.API_POINT;
    }

    public String getId()
    {
      return mId;
    }
  }

  public static class MyPosition extends MapObject
  {
    public MyPosition(String name, double lat, double lon)
    {
      super(name, lat, lon, "");
    }

    protected MyPosition(Parcel source)
    {
      super(source);
    }

    @Override
    public MapObjectType getType()
    {
      return MapObjectType.MY_POSITION;
    }

    @Override
    public void setDefaultIfEmpty(Resources res)
    {
      if (TextUtils.isEmpty(mName))
        mName = res.getString(R.string.my_position);
    }
  }

}
