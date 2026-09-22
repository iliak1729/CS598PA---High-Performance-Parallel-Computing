CC = mpicc
CFLAGS = -O2 -Wall

MSG_DIR = ../../Dependencies/msg_passing_files

TARGET = ping_pong
SRC = driver.c ping_pong.c $(MSG_DIR)/msg_mpi.c

all: $(TARGET)

$(TARGET):
	$(CC) $(CFLAGS) -I$(MSG_DIR) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)