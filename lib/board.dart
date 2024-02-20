import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tetris/pixel.dart';
import 'package:tetris/values.dart';
import 'piece.dart';

List<List<Tetromino?>> gameBoard = List.generate(
  colLength, 
  (i) => List.generate(
    rowLength,
    (j) => null,

  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {

  // current tetoris piece
  Piece currentPiece = Piece(type: Tetromino.Z);

  // current score

  int currentScore = 0;

  //  game over status

  bool gameOver = false;
  
  @override
  void initState() {
    super.initState();

    // start game when app starts

    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();

    Duration frameRate = const Duration(milliseconds: 300);
    gameLoop(frameRate);

  }

  void gameLoop(Duration frameRate) {
    Timer.periodic(
      frameRate,
      (timer) {
        setState(() {
          clearLine();
          checkLanding();
          if (gameOver == true) {
            timer.cancel();
            showGameOverMessageDialog();
          }
          currentPiece.movePiece(Direction.down);
        });
      }
    );
  }


// game over message

void showGameOverMessageDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
    title: Text('Game Over'),
    content: Text('Your score is: $currentScore'),
    actions: [
      TextButton(
        onPressed: () {
        // resteat method
        restartGame();
        Navigator.pop(context);
      },
       child: Text('Play Again'))
     ],
    ),
  );
}

void restartGame() {
  gameBoard = List.generate(
      colLength, 
      (i) => List.generate(
      rowLength,
      (j) => null,
    ),
  );

  gameOver = false;
  currentScore = 0;
  createNewPiece();
  startGame();
}

// check for collision in a future position
// T->collision, F->no collision

  bool checkCollision(Direction direction) {
    // loop through each position of the current piece
    for (int i=0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) { 
        row += 1;
      }

      if (row >= colLength || col < 0 || col >= rowLength)  {
        return true;
      }
    }
    return false;
  }

  void checkLanding() {
    if (checkCollision(Direction.down) || checkLanded()) {
      for (int i=0; i<currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row>=0 && col>=0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }
      createNewPiece();
    }
  }

  void createNewPiece() {
    Random rand = Random();
    Tetromino randomType = 
      Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    if (isGameOver()) {
      gameOver = true;
    }
  }

  bool checkLanded() {
    // loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // check if the cell below is already occupied
      if (row + 1 < colLength && row >= 0 && gameBoard[row + 1][col] != null) {
        return true; // collision with a landed piece
      }
    }

    return false; // no collision with landed pieces
  }

  // clear line

  void clearLine() {
    for (int row = colLength - 1; row >= 0; row--) {

    bool rowIsFull = true;

      for (int col = 0; col < rowLength; col ++) {
        if (gameBoard[row][col] == null) {
            rowIsFull = false;
            break;
        }
      }

        if (rowIsFull) {
          for (int r = row; r > 0; r--) {
            gameBoard[r] = List.from(gameBoard[r-1]);
          }
          gameBoard[0] = List.generate(row, (index) => null);
          currentScore ++ ;
        }
    }
  }

  // game over method
  bool isGameOver() {

    for (int col = 0; col < rowLength; col ++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }
    return false;
  }

  // controll method

  void moveLeft() {
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }

  }

  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
              Expanded(
                child: GridView.builder(
                  itemCount: rowLength * colLength,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: rowLength), 
                  itemBuilder: (context, index) {
                      
                    int row = (index / rowLength).floor();
                    int col = index % rowLength;
                      
                    // current piece
                    if (currentPiece.position.contains(index)) {
                      return Pixel(
                        color: currentPiece.color,
                        child: index,
                      );
                    } 
                    
                    // landed pieces
                      else if (gameBoard[row][col] != null) {
                        final Tetromino? tetrominoType = gameBoard[row][col];
                        return Pixel(color: tetrominoColors[tetrominoType], child: '');
                      }
                      
                    // brank pixel
                    
                    
                    else {
                      return Pixel(
                        color: Colors.grey[900],
                        child: index,
                      );
                    }
                  },
                ),
              ),
              

              Text(
                'Score: $currentScore',
                style: TextStyle(color: Colors.white),
                ),

              //  controller
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0, top: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:[
                      IconButton(
                        onPressed: moveLeft,
                        color: Colors.white, 
                        icon: Icon(Icons.arrow_back_ios),
                      ),
                      IconButton(
                        onPressed: rotatePiece, 
                        color: Colors.white,
                        icon: Icon(Icons.rotate_right),
                      ),
                      IconButton(
                        onPressed: moveRight, 
                        color: Colors.white,
                        icon: Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                )
            ],
          ),
    );
  }
}