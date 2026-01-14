---
title = '[Shutlock 2025] Not Fair'
date = '2025-06-30'
tags = ['ctf-writeup', 'reverse-engineering', 'english']
---

> [!instructions] 
> 
> 🇫🇷 Un adversaire redoutable se cache dans ce binaire. Votre but est de le vaincre. Mais prenez garde... la vie n'est pas toujours juste.
> 
> 🇬🇧 An impressive adversary lurks within this binary. Your goal is to beat it, but take care... life is not always fair.


The provided binary does not do anything when executed without an argument. With a random string as an argument, we get a mesage : `You lost :/`. 

Let's decompile it. 

After identifying the `main` function, we can see that it is saving the first character of the argument, and checking if it is between `'a'` and `'g'`. We can also note that the first letter must have an even ascii code, so it can only be `'b'`, `'d'` or `'f'`

```c
if (argc == 2) {
  char* string_argument = argv + 8;
  saved_string_argument = string_argument; // Memory section / global variable
  int len_arg = strlen(string_argument);
  saved_len_arg = len_arg; // Memory section / global variable
  if (len_arg < 2) {
    return_value = 1;
  } else {
    memory_zone = *string_argument;
    if ((memory_zone < 97) || ('g' < memory_zone)) {
      lose();
    }
    // Only even letters are accepted
    if ((*string_argument & 1) != 0) {
      lose();
    }
  }
  [...]  
}
```

Then, a 3D "grid" is initialized and filled with the character `'2'` using sizes hardcoded in the binary. At indexes 2 and 3, it sets the character `'0'`.

```c
void init_3D_grid(void) {
  ulong j;
  ulong i;
  
  grid = malloc((long)(int)((uint)value1 * (uint)value2));
  for (i = 0; i < value2; i = i + 1) {
    for (j = 0; j < value1; j = j + 1) {
      grid[j + value1 * i] = '2';
    }
  }
  grid[2] = '0';
  grid[3] = '0';
  return;
}
```

After initializing everything, it calls a function I renamed `multiple_functions`, because... it is calling multiple functions. This function is called n times, n being the length of the argument.

```c
multiple_functions(*string_argument);
for (i = 1; i < len_arg; i = i + 1) {
  multiple_functions(string_argument[i]);
}
```

By looking into these functions, it appears that this binary is simulating a [connect 4](https://en.wikipedia.org/wiki/Connect_Four) game. The `play` function is quite simple. It takes the index of the column where you want to play (a connect 4 grid is made of 7 columns, here from letter 'a' to letter 'g') and place the pieces in the bottom of the grid, on top of the highest piece if the column is not empty.

```c
void play(int index,int player_id)

{
  ulong i;
  bool result;
  
  result = false;
  i = 0;
  do {
    if (value2 <= i) {
	  LAB_00401363:
      if (!result) {
        lose();
      }
      return;
    }
    if (grid[index + value2 * i] == '2') { // The box is empty
      if (player_id == L'0') { // Adversary is playing
        grid[index + value2 * i] = '0';
      }
      else { // We are playing
        grid[index + value2 * i] = '1';
      }
      result = true;
      goto LAB_00401363; // ghidra being weird
    }
    i = i + 1;
  } while( true );
}

```

This function is first called with our player id (1). Then, win conditions are checked. I won't show the function because it is quite long, but it is checking if four pieces are aligned in vertical, horizontal or diagonal in both directions. It is also checking if the game is still valid (no cheating).

After that, it's the ennemy turn. Enemy moves are stored in the binary memory. To find the right move, it uses a xor with the first character from the player's sequence of moves. There is also a check for the turn number. If it's the 2nd or the 4th turn, the enemy will play two times.

```c
void ennemy_turn(int param_1) {
  [...]
  int turn = value // a value in memory
  value = value + 1;
  turn = first_character ^ (&ennemy_moves)[turn]; // ennemy move is decoded from xoring it with the first character in the argument
  if ((turn < 'a') || ('g' < turn)) {
    lose();
  }
  play(turn - 0x61,'0'); // play as the enemy
  if ((param_1 == 0) && ((value == '\x02' || (value == '\x04')))) { // ennemy play two times on turn 2 and 4
    ennemy_turn(1);
  }
  return;
}
```

After that it checks for the win condition again. If the player win, it calls a function that takes the SHA1 of the moves sequence, and print it as the flag.

Now we know what to do to ge the flag : find a sequence of moves that win the game. We know that the grid is intially like this :

```text
0000000
0000000
0000000
0000000
0000000
00XX000
```

We also know that the ennemy will play two times on turns 2 and 4

What a great opportunity to bring out my Connect 4 game!

![Pasted image 20250625235730](img/Pasted%20image%2020250625235730.png)

I found my opponent moves with this small python script :

```python
moves_to_xor = [0x07, 0x06, 0x06, 0x07, 0x04, 0x07, 0x05, 0x01, 0x00, 0x04, 0x00]

for k in [ord(c) for c in ["b", "d", "f"]]:
    [print(chr(k ^ move), end="") for move in moves_to_xor]
    print("")
```

If the first move is something else than 'b', it will create ennemy moves that are not characters from 'a' to 'g' and lead to a lose. By starting at position 'b', we can easily find the right sequence of moves, which is `bfdcegfd` :

![Pasted image 20250626001222](img/Pasted%20image%2020250626001222.png)

```text
turn  me  ennemy   
0:    b   e
1:    f   d
2:    /   d
3:    d   e
4:    /   f
5:    c   e 
6:    e   g
7:    g   c
8:    f   b
9:    d   f
```

And we get the flag !

![Pasted image 20250626000427](img/Pasted%20image%2020250626000427.png)
