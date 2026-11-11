# Weather Reimagined: notes for modders

Snow and flames are generated from each object's own texture, so most mods need no patches. The cases below need a small addition.

## Eaves from other mods

Eaves need to be marked so the mod knows where to add snow and stop rain and snow at the roof edge.

You can add this extension to the eave's ThingDef:

```xml
<modExtensions>
  <li Class="WeatherReimagined.EaveExtension" />
</modExtensions>
```

Alternatively, you can list eaves in a separate def without changing the original mod. You can also add entire designation categories:

```xml
<WeatherReimagined.EaveListDef>
  <defName>MyMod_Eaves</defName>
  <eaves>
    <li>MyMod_Eave</li>
  </eaves>
  <designationCategories>
    <li>MyMod_EaveCategory</li>
  </designationCategories>
</WeatherReimagined.EaveListDef>
```

## Flames on buildings

Buildings with an open fire, such as furnaces or candles, get flames at fixed spots. Add this comp to the ThingDef, with one entry per flame:

```xml
<li Class="LivingFire.CompProperties_Flammenstellen">
  <fires>
    <li>
      <offset>(0.00, 0, -0.04)</offset>
      <size>0.95</size>
    </li>
  </fires>
</li>
```

Use `firesNorth`, `firesEast`, `firesSouth` and `firesWest` to set different spots per rotation. With `<onlyWhenUsed>true</onlyWhenUsed>`, the flames only burn while the building is in use. Otherwise they follow the building's light or fuel.

Each flame has its own position and size. The offset is measured in cells from the center of the building: the first value moves the flame left or right, the last value moves it down or up. This way you can place flames exactly where the fire is in your texture.

Small flames, for example on candles, work the same way if you like to add them: put one entry on each wick, use a small size of about 0.2 to 0.3 and `<roundBase>true</roundBase>` for a round flame base like a candle flame.

To shape the flames exactly, add a fire mask next to the building's texture, for example *Things/MyFurnace_south_firemask.png* and the same for north, east and west. Opaque pixels mark where the flames burn. A missing direction is taken from another one.

## Excluding objects from snow

You can exclude objects from the generated snow. Excluded plants will keep their vanilla snow appearance, while excluded buildings, items and eaves will not get snow. Ground snow is unaffected.

Add this extension to the ThingDef:

```xml
<modExtensions>
  <li Class="WeatherReimagined.NoSnowExtension" />
</modExtensions>
```

Alternatively, list the defs in a separate def without changing the original mod. Unknown names are skipped, so MayRequire is not needed:

```xml
<WeatherReimagined.NoSnowListDef>
  <defName>MyMod_NoSnow</defName>
  <defs>
    <li>SomeThingDefName</li>
  </defs>
  <designationCategories>
    <li>SomeDesignationCategoryDefName</li>
  </designationCategories>
</WeatherReimagined.NoSnowListDef>
```
