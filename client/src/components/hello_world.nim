# Import HappyX
import happyx


# Declare component
component HelloWorld:
  # Declare HTML template
  `template`:
    tDiv(class = "someClass"):
      "Hello, world!"
  `script`:
    echo "Start coding!"
