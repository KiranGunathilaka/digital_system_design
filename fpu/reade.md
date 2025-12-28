g++ -O2 -std=c++11 -o test test.cpp

sudo usermod -a -G dialout $USER
sudo chmod a+rw /dev/ttyUSB0