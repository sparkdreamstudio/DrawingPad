# Architecture
    1. The main architecture of application is MVC.
    2. I used the the proxy pattern for the File access. Although I did not implement the functionality of firebase, it is easy to extention to that function\
    3. For the canvas drawing, I used command pattern. For each kind of brush, canvas need not care about detail of brush. In the future, I event could add a lots of other kind of brush without modifying the canvas code.
# Decision for technical choices and trade-off
    1. The most important part is drawing. Hence, I decided that I should insure that experience of drawing. I decided buffer the privious the drawing on the UIImage. By this way, the touch sampling rate would not decrease when the stroke amount is very large comparing the redraw every stroke every time.
    2. Due the iOS memory management is very sensitive. I could not buffer the whole canvas if the canvas size is very large (At this application, I give canvas a fixed size (2000*2000)). Hence, I decide only buffer the visible part of canvas.By this way, I could make drawing job is smooth and memory usage is low. 
    3. The trade off of my method is that scrolling of the canvas is not smooth. But I though it's acceptable.


