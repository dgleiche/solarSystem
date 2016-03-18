import peasy.*;
import java.util.*;
import g4p_controls.*;

PeasyCam cam;

Planet sun;

ArrayList<Planet> planets;

//CONSTANTS
final double G = 6.67300e-11;  

//Scale between pixels and mi
final float SCALE = 10000.0;

//Found this scale factor to work best for location
final float SCALELOC = SCALE * 50;

//Gain for speed of planets
//Yeah. Planets move relatively slow
final float VELOCITYSCALE = pow(10, 4);

//Class holds data for editing window
class EditWinData extends GWinData {
  PlanetData planetData;
}

//Class to store planet data
class PlanetData {
  //Various variables for critical data
  float rad;
  
  double mass;
  
  PImage texture;
  
  PVector loc;
  
  String name;
  
  //The shape object that is drawn to the screen will be stored here
  PShape shape;
  
  float distFromSun;
  
  PVector velocity;
  
  /* Various overloads for constructing a planet data, with a varying level of defaults assumed */
  
  //Assumes a start location a radius of the distance away from the sun as the x value, and 0 for the y value
  PlanetData(float _rad, double _mass, PImage _texture, float _distFromSun, String _name) {
    rad = _rad;
    mass = _mass;
    name = _name;
    texture = _texture;
    distFromSun = _distFromSun;
    setStartLoc();
    spawnShape();
  }
  
  //Assumes texture as a web URL
  PlanetData(float _rad, double _mass, String _texture, float aphelionDist, float aphelionVel, String _name) {
    rad = _rad;
    mass = _mass;
    name = _name;
    texture = loadImage(_texture);
    distFromSun = aphelionDist;
    setStartLoc();
    velocity = new PVector(0, aphelionVel);
    spawnShape();
  }
  
  //Allows control over location
  PlanetData(float _rad, double _mass, PImage _texture, PVector _loc, String _name) {
    rad = _rad;
    mass = _mass;
    name = _name;
    texture = _texture;
    loc = _loc;
    spawnShape();
  }
  
  //Control over location & ability to use a URL as texture
  PlanetData(float _rad, double _mass, String _texture, PVector _loc, String _name) {
    rad = _rad;
    mass = _mass;
    name = _name;
    texture = loadImage(_texture);
    loc = _loc;
    spawnShape();
  }
  
  //Ability to set a custom scale (necessary for the sun to be scaled down some since it's so darn big)
  PlanetData(float _rad, double _mass, String _texture, PVector _loc, float newScale, String _name) {
    rad = _rad;
    mass = _mass;
    name = _name;
    texture = loadImage(_texture);
    loc = _loc;
    spawnShape(newScale);
  }
  
  //Assumes the radius will be scaled down by a constant factor
  //Determined through trial and error of what looked right
  void spawnShape() {
    shape = createShape(SPHERE, rad/(SCALE/10));
    shape.setTexture(texture);
  }
  
  void spawnShape(float scale) {
    shape = createShape(SPHERE, rad/(scale));
    shape.setTexture(texture);
  }
  
  void setStartLoc() {
    loc = new PVector(distFromSun + rad + sun.data.rad, 0);
  }
}

//Various helpful conversions
double milesToMeters(double miles) {
  return miles*1609.34;
}
  
double metersToMiles(double meters) {
  return meters/1609.34;
}

class Planet {  
  PlanetData data;
  
  //For calculating when orbits occur
  double prevTheta = 0;
  
  //Number of times planet has orbitted sun
  float orbits = 0;
  
  //A planet data object must be sufficiently created before the planet
  Planet(PlanetData _data) {
    data = _data;
  }
  
  void move() { 
    //Multiply by the scaling factor as to not take a year
    PVector accel = calcAccel().mult(VELOCITYSCALE);

    //Integrate acceleration
    data.velocity.add(accel);

    //Integrate velocity (and scale it up)
    data.loc.add(data.velocity.x * VELOCITYSCALE, data.velocity.y * VELOCITYSCALE);

    data.distFromSun = data.loc.dist(sun.data.loc);
    
    //Orbits occur on a sign change of - to + wrt theta
    if (prevTheta > 0 && calcTheta() < 0) orbits++;
    
    prevTheta = calcTheta();
  }
  
  PVector calcAccel() {
    PVector force = PVector.sub(sun.data.loc, data.loc);
    
    float dist = force.mag();

    //Normalize to find direction
    force.normalize();
    
    // Fg = GMm / r^2
    //Also have to double covert to miles due to the m^2
    double fg = metersToMiles(metersToMiles((G*sun.data.mass*data.mass) / (milesToMeters(dist*dist))));
    
    force.mult((float)fg);
    
    //Convert to acceleration
    force.div((float)data.mass);

    return force;
  }
  
  double calcTheta() {
    return Math.atan2(this.data.loc.y, this.data.loc.x);
  }
}

//Window for editing info
GWindow editWindow;

void setup() {
  //fullScreen(P3D);
  size(1000,700,P3D);
  cam = new PeasyCam(this, 5000);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(30000);
  
  cursor(CROSS);
  
  noStroke();
  
  planets = new ArrayList<Planet>();

  //Initialize all the planets with their respective data
  
  PlanetData sunData = new PlanetData(432474, 1.989e30, "http://www.solarsystemscope.com/nexus/textures/texture_pack/assets/preview_sun.jpg", new PVector(0, 0), SCALE, "Sun");
  sun = new Planet(sunData);
  
  PlanetData mercuryData = new PlanetData(1516, 3.285e23, "http://laps.noaa.gov/albers/sos/mercury/mercury/mercury_rgb_cyl_www.jpg", (float)metersToMiles(69.82e9), (float)metersToMiles(-38860), "Mercury");
  Planet mercury = new Planet(mercuryData);
  planets.add(mercury);
  
  PlanetData venusData = new PlanetData(3760, 4.867e24, "http://maps.jpl.nasa.gov/pix/ven0ajj2.jpg", (float)metersToMiles(108.94e9), (float)metersToMiles(-34790), "Venus");
  Planet venus = new Planet(venusData);
  planets.add(venus);
  
  PlanetData earthData = new PlanetData(3959, 5.972e24, "https://9to5google.files.wordpress.com/2013/06/1.jpg", (float)metersToMiles(152.1e9), (float)metersToMiles(-29290), "Earth");
  Planet earth = new Planet(earthData);
  planets.add(earth);

  PlanetData marsData = new PlanetData(2106, 6.39e23, "http://www.solarsystemscope.com/nexus/textures/texture_pack/assets/preview_mars.jpg", (float)metersToMiles(249.23e9), (float)metersToMiles(-21970), "Mars");
  Planet mars = new Planet(marsData);
  planets.add(mars);
  
  PlanetData jupiterData = new PlanetData(43441, 1.89e27, "http://laps.noaa.gov/albers/sos/jupiter/jupiter/jupiter_rgb_cyl_www.jpg", (float)metersToMiles(816620e6), (float)metersToMiles(-12440), "Jupiter");
  Planet jupiter = new Planet(jupiterData);
  planets.add(jupiter);
  
  PlanetData saturnData = new PlanetData(36184, 5.683e26, "http://orig13.deviantart.net/b322/f/2014/306/2/4/saturn_texture__3_2k____storm_by_hellcatf6f-d84xlbn.png", (float)metersToMiles(1514500e6), (float)metersToMiles(-9090), "Saturn");
  Planet saturn = new Planet(saturnData);
  planets.add(saturn);
  
  PlanetData uranusData = new PlanetData(15756, 8.681e25, "http://textures.forrest.cz/textures/library/maps/Uranus.jpg", (float)metersToMiles(3003620e6), (float)metersToMiles(-6490), "Uranus");
  Planet uranus = new Planet(uranusData);
  planets.add(uranus);
  
  PlanetData neptuneData = new PlanetData(15299, 1.024e26, "http://paulbourke.net/texture_colour/space/neptune.jpg", (float)metersToMiles(4545670e6), (float)metersToMiles(-5370), "Neptune");
  Planet neptune = new Planet(neptuneData);
  planets.add(neptune);
}

int frame = 0;

void draw() { 
    background(0);
    fill(246, 225, 65);
    
    lights();
    
    drawHUD();
    
    //The sun is constant — it isn't part of the planets array
    shape(sun.data.shape, sun.data.loc.x, sun.data.loc.y);
    
    //Loop through and draw each planet in the planets array
    for (Planet planet : planets) {
      shape(planet.data.shape, planet.data.loc.x/SCALELOC, planet.data.loc.y/SCALELOC);
      
      planet.move();
    }
    
    if (frame >= 3 && follow != null) {
      cam.lookAt(follow.data.loc.x/SCALELOC, follow.data.loc.y/SCALELOC, follow.data.loc.z/SCALELOC);
      cam.setDistance(150);
      cam.setRotations(-Math.PI/2, -1*(follow.calcTheta()-Math.PI/2), 0);
      
      frame = 0;
    }

    frame++;
}

Planet follow = null;

void keyPressed() { 
  //Edit follow info
  switch (key) {
    case '1':
      follow = planets.get(0);
      break;
    case '2':
      follow = planets.get(1);
      break;
    case '3':
      follow = planets.get(2);
      break;
    case '4':
      follow = planets.get(3);
      break;
    case '5':
      follow = planets.get(4);
      break;
    case '6':
      follow = planets.get(5);
      break;
    case '7':
      follow = planets.get(6);
      break;
    case '8':
      follow = planets.get(7);
      break;
    default:
      //Only turn off follow if we didn't press enter
      if ((int)key != 10) follow = null;
      break;
  }
  
  //If enter was pressed, edit planet info if following a planet
  if ((int)key == 10 && follow != null) {
    spawnEditWindow();
  }
}

/* GUI COMPONENTS FOR WINDOW */
//Buttons
GButton confirmBtn, cancelBtn;

//Textfields for changing values
GTextField massField, radiusField, distField;

//Cuz G4P doesn't provide a setup function... derp :(
boolean editWindowSetup = false;

//Create a new G4P window for editing planet info (the simulation stuff)
void spawnEditWindow() {
  //One last (unnecessary) check
  if (follow != null) {
    editWindow = GWindow.getWindow(this, "Edit " + follow.data.name, 500, 50, 500, 200, JAVA2D);
    
    editWindow.setActionOnClose(GWindow.CLOSE_WINDOW);
    
    //Pass in the planet as data
    editWindow.addData(new EditWinData());
    ((EditWinData)editWindow.data).planetData = follow.data;
    
    editWindowSetup = false;
    
    //Event handlers
    editWindow.addDrawHandler(this, "editWinDraw");
    editWindow.addOnCloseHandler(this, "editWinClosed");
    editWindow.addPreHandler(this, "editWinSetup");
  }
}

/* EDIT WINDOW HANDLERS */

void editWinSetup(PApplet app, GWinData winData) {
  if (!editWindowSetup) {
    PlanetData data = ((EditWinData)winData).planetData;
    
    //Field defaults
    massField = new GTextField(app, 10, 20, 200, 20);
    massField.tag = "massField";
    massField.setPromptText("Mass: " + data.mass + " kg");
    
    radiusField = new GTextField(app, 10, 50, 200, 20);
    radiusField.tag = "radiusField";
    radiusField.setPromptText("Radius: " + data.rad + " mi");
    
    distField = new GTextField(app, 10, 80, 200, 20);
    distField.tag = "distField";
    distField.setPromptText("Distance: " + data.distFromSun + " mi");
    
    //Buttons
    confirmBtn = new GButton(app, 10, 130, 140, 20, "OK");
    cancelBtn = new GButton(app, 340, 130, 140, 20, "Cancel");
    
    //Setup complete
    editWindowSetup = true;
  }
}

void editWinDraw(PApplet app, GWinData winData) {
  app.background(255);
}

void editWinClosed(PApplet app, GWinData winData) {
  println("Closed");
}

//Button presses in window
void handleButtonEvents(GButton button, GEvent event) {
  if (button == confirmBtn && event == GEvent.CLICKED) {
    try {
      double mass = (massField.getText() == "") ? follow.data.mass : Double.parseDouble(massField.getText());
      float rad = (radiusField.getText() == "") ? follow.data.rad : Float.parseFloat(radiusField.getText());
      float dist = (distField.getText() == "") ? follow.data.distFromSun : Float.parseFloat(distField.getText());
    
      follow.data.mass = mass;
      
      //Resizing is done by a percent scale
      follow.data.shape.scale(rad/follow.data.rad);
      
      follow.data.rad = rad;
      follow.data.distFromSun = dist;
      
      //Also gotta respawn at new location (new distance)
      follow.data.setStartLoc();
      
      editWindow.close();
    } catch (Exception ex) {
      //Invalid number format -- boo
      //Invalid formatting is the meaning of life
      println("ERR 41: Invalid Number Format");
    }
  } else if (button == cancelBtn && event == GEvent.CLICKED) {
    //Exit out
    editWindow.close();
  }
}

void drawHUD() {
  cam.beginHUD();
  
  //If we're currently following a planet, print out its info
  if (follow != null) {
    
    textSize(20);
    
    text("Planet: " + follow.data.name, 10, 30); 
    text("Mass: " + follow.data.mass + " kg", 10, 60);
    text("Radius: " + follow.data.rad + " mi", 10, 90);
    text("Velocity: " + nfc((float)follow.data.velocity.mag(), 3) + " mi/sec", 10, 120);
    text("Distance from Sun: " + follow.data.distFromSun + " mi", 10, 150);
    text("Number of Orbits: " + follow.orbits, 10, 180);
    
    //Also allow the user to do their thing
    text("Press Enter to Edit Planet Information", width - 400, 30);
    
  }
  
  cam.endHUD();
}

void mousePressed() {
  follow = null;
}