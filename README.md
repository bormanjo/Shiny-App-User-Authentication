# A Template for Simple User Authentication

A quick reference for those looking to build a simple interface for user login on their Shiny App. Particularly useful for those not looking to pay for the premium ShinyApps login feature.

## Disclosure

I do not study cryptography nor can I say that this is a secure authentication procedure.

## How it Works

- Creates a SQLite database for storing information. The 'users' table houses the username and hashed passwords for all registered users.
- User switches between two renderUI() functions depending on the login status.
- If an account does not exist, the user can create an account. The username is stored in plaintext along with the hashed password text using the sha256() function from the openssl library
- If an account exists, the user can login with the corresponding username and password. The loggedIn status of the app changes and the UI changes.
- After logging in, the user can logout by clicking the action-link in the top right.
- A log of actions can be found in the console.

## Potential improvements

- Password resets
- More detailed user registration form (re-type password, user email)
- Verify password authentication with cryptography standards
