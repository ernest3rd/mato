import processing.core.*;

int[] canvas;
float speed;
int len;
int score;
int scoreDisp;
boolean dead;
PVector position = new PVector(),
        velocity = new PVector();
boolean[] isKeyDown = new boolean[100];

final int SNAKE_SIZE = 8;
final int UIBAR_ADDR = 1;
final int APPLE_ADDR = 10;
final int SNAKE_ADDR = 100;

// Fonts
PFont f18, f24, f40;

void setup(){
  size(800,500);
  frameRate(60);
  
  canvas = new int[width*height];
  len = 40;
  speed = 3;
  score = 0;
  scoreDisp = score;
  dead = true;
  position = new PVector(width/2, height/2);
  velocity = new PVector(speed, 0.0);
  
  addUIBar();
  addApple();

  loadPixels();
  noStroke();
  fill(0);
  f18 = loadFont("Monospaced-18.vlw");
  f24 = loadFont("Monospaced-24.vlw");
  f40 = loadFont("Skia-80.vlw");
}

void draw(){
  if(!dead){
    if(isKeyDown[LEFT]){
      velocity.rotate(-0.1);
    }
    else if (isKeyDown[RIGHT]){
      velocity.rotate(0.1);
    }
    position = position.add(velocity);
    
    boolean timeToGrow = false;
    
    for(int y=-SNAKE_SIZE; y<SNAKE_SIZE; y++){
      for(int x=-SNAKE_SIZE; x<SNAKE_SIZE; x++){
        if(x*x+y*y < SNAKE_SIZE * SNAKE_SIZE){
          int collision = checkCollision(int(position.x)+x, int(position.y)+y);
          if(collision > 0){
            if(collision == SNAKE_ADDR || collision == UIBAR_ADDR){
              dead = true;
            }
            else if(collision == APPLE_ADDR){
              removeApple(int(position.x)+x, int(position.y)+y);
              addApple();
              timeToGrow = true;
            }
          }
          else {
            addCanvasPixel(int(position.x)+x, int(position.y)+y, SNAKE_ADDR);
          }
        }
      }
    }
    
    if(timeToGrow){
      score+=12345;
      growSnake();
    }
  }
  
  for(int i=0; i<canvas.length; i++){
    if(canvas[i]==0){
      pixels[i] = 0xffffffff;
    }
    else if(canvas[i]==UIBAR_ADDR){
      pixels[i] = 0xff888888;
    }
    else if(canvas[i] == APPLE_ADDR){
      pixels[i] = 0xffdd0000;
    }
    else if(canvas[i] >= SNAKE_ADDR){
      float phase = sin(canvas[i]/3.0);
      int r = int(phase * 20) + 40;
      int g = int(phase * 30) + 215;
      int b = int(phase * 30) + 215;
      if(canvas[i] > SNAKE_ADDR + len){
        canvas[i] = 0;
      }
      else if(!dead){
        canvas[i]++;
        pixels[i] = 0xFF000000 + (r << 16) + (g << 8) + b;
      }
      else {
        int gray = (r+g+b)/3;
        pixels[i] = 0xFF000000 + (gray << 16) + (gray << 8) + gray;
      }
    }
  }
  
  // Draw face
  PVector dir = new PVector(velocity.x, velocity.y).normalize();
  dir = dir.mult(SNAKE_SIZE/1.2);
  drawEye(PVector.add(position, dir.rotate(-2)), 6);
  drawEye(PVector.add(position, dir.rotate(4)), 6);
  
  updatePixels();
  
  // Draw text
  if(score > scoreDisp){
    scoreDisp += 1234;
  }
  else if(scoreDisp>score){
    scoreDisp = score;
  }
  
  textFont(f24);
  textAlign(LEFT, CENTER);
  text("Score: " + scoreDisp, 10, 25);
  textAlign(RIGHT, CENTER);
  textFont(f40);
  textSize(24);
  text("MATO", width-10, 25);
  
  if(dead){
    textFont(f40);
    textAlign(CENTER, CENTER);
    text("MATO", width/2, height/2 - 40);
    
    textFont(f18);
    text("PRESS SPACE TO START A NEW GAME", width/2, height/2+14);
  }
}

void reset(){
  position.x = width/2;
  position.y = height/2;
  velocity.rotate(random(10));
  dead = false;
  score = 0;
  len = 40;
  addUIBar();
  addApple();
}

int checkCollision(int x, int y){
  int pos = x + y * width;
  
  // Check top and bottom edges
  if(pos < 0 || pos > canvas.length || x < 0 || x > width){
    return SNAKE_ADDR;
  }
  
  // UI BAR
  if(canvas[pos] == UIBAR_ADDR){
    return UIBAR_ADDR;
  }
  
  // Check collision with apple
  if(canvas[pos] == APPLE_ADDR){
    return APPLE_ADDR;
  } 
  
  // Check collision with self
  if(canvas[pos] > SNAKE_ADDR + 20){
    return SNAKE_ADDR;
  } 
  
  return -1;
}

void addCanvasPixel(int x, int y, int l){
  int pos = x + y * width;
  if(pos > 0 && pos < canvas.length){
    canvas[pos] = l;
  }
}

void addCanvasRectangle(int x, int y, int w, int h, int c){
  for(int i = 0; i < h; i++){
    for(int j = 0; j < w; j++){
      int pos = (x + j) + (y + i) * width;
      canvas[pos] = c;
    }
  }
}

void addApple(){
  int csize = 15;
  int csize2 = csize*csize;
  int pos = int(random(canvas.length));
  int y = int(pos / width);
  int x = int(pos - y * width);
  
  for(int dy=-csize; dy<csize; dy++){
    for(int dx=-csize; dx<csize; dx++){
      if(dx*dx+dy*dy < csize2){
        int collision = checkCollision(x+dx, y+dy);
        if(collision > 0){
          removeApple(x, y);
          addApple();
          return;
        }
        addCanvasPixel(x+dx, y+dy, APPLE_ADDR);
      }
    }
  }
}

void addUIBar(){
  addCanvasRectangle(0,0,width,height, UIBAR_ADDR);
  addCanvasRectangle(10,50,width-20, height-60, 0);
}

void removeApple(int x, int y){
  int csize = 40;
  for(int dy=-csize; dy<csize; dy++){
    for(int dx=-csize; dx<csize; dx++){
      int pos = (x+dx) + (y+dy) * width;
      if(pos > 0 && pos < canvas.length){
        if(canvas[pos] == APPLE_ADDR){
          canvas[pos] = 0;
        }
      }
    }
  }
}

void growSnake(){
  len+=40;
}

void drawPixel(int x, int y, int c){
  int pos = x + y * width;
  if(pos > 0 && pos < pixels.length){
    pixels[pos] = c;
  }
}

void drawEye(PVector pos, int eyeSize){
  if(!dead){
    drawCircle(int(pos.x), int(pos.y), eyeSize, 0xff33dddd);
    drawCircle(int(pos.x), int(pos.y), eyeSize-1, 0xffffffff);
    drawCircle(int(pos.x), int(pos.y), eyeSize-3, 0xff000000);
  }
}

void drawCircle(int x, int y, int csize, int c){
  int csize2 = csize*csize;
  for(int dy=-csize; dy<csize; dy++){
    for(int dx=-csize; dx<csize; dx++){
      if(dx*dx+dy*dy < csize2){
        drawPixel(x+dx, y+dy, c);
      }
    }
  }
}

void keyPressed(){
  if(keyCode < 100){
    isKeyDown[keyCode] = true;
  }
}

void keyReleased(){
  if(keyCode < 100){
    isKeyDown[keyCode] = false;
    if(dead && keyCode==32){
      reset();
    }
  }
}
