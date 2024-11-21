#!/bin/bash

echo -e "\nEnter your username:"
read USERNAME

while [ -z $USERNAME ] 
do
  echo -e "\nPlease enter your username"
  read USERNAME
done

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
#CONCAT(UPPER(SUBSTR(name, 1, 1)), LOWER(SUBSTR(name, 2, LENGTH(name)-1))) AS uname
USER_EXIST=$($PSQL "SELECT COUNT(*) AS games_played, MIN(nb_guesses) AS best_game, name AS username FROM games INNER JOIN users USING(user_id) WHERE name = LOWER('$USERNAME') GROUP BY users.name")

if [[ $USER_EXIST ]]
then
  echo $USER_EXIST | while IFS=\| read games_played best_game username
  do
    echo -e "\nWelcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
  done
else
  INSERT_USER=$($PSQL "INSERT INTO users(name) VALUES(LOWER('$USERNAME'))")

  if [[ $INSERT_USER == "INSERT 0 1" ]]
  then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  fi
fi

MIN=1
MAX=1000

echo -e "\nGuess the secret number between $MIN and $MAX:"
read USER_NBRAND

while [[ $USER_NBRAND =~ ^[^0-9]*$ || -z $USER_NBRAND ]]
do
  echo -e "\nThat is not an integer, guess again:"
  read USER_NBRAND
done

# Generate secret random number
#SECRET_NUMBER=$(shuf -i $MIN-$MAX -n 1)
SECRET_NUMBER=$(($MIN + RANDOM % $MAX))
# Number of tentative
number_of_guesses=1

FIND_SECRET=FALSE

while [[ $FIND_SECRET == FALSE ]]
do
  if [[ $USER_NBRAND -lt $SECRET_NUMBER ]]
  then
    ((number_of_guesses++))
    echo -e "\nIt's higher than that, guess again:"
    read USER_NBRAND
  elif [[ $USER_NBRAND -gt $SECRET_NUMBER ]]
  then
    ((number_of_guesses++))
    echo -e "\nIt's lower than that, guess again:"
    read USER_NBRAND
  else
    FIND_SECRET=TRUE
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = LOWER('$USERNAME')")
    INSERT_GAMES=$($PSQL "INSERT INTO games(nb_random, nb_guesses, user_id) VALUES('$SECRET_NUMBER', '$number_of_guesses', '$USER_ID')")

    if [[ $INSERT_GAMES == "INSERT 0 1" ]]
    then
      echo -e "\nYou guessed it in $number_of_guesses tries. The secret number was $SECRET_NUMBER. Nice job!"
    fi
  fi
done
