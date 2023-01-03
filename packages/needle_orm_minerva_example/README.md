# needle_orm_minerva_example

A new Minerva project.

## Getting Started

This project is a starting point for a Minerva application.

A few resources to get you started if this is your first Minerva project:

- [Documentation](https://github.com/GlebBatykov/minerva)
- [Examples](https://github.com/GlebBatykov/minerva_examples)

## Run

`minerva run`

## build

`minerva build`

## login

    curl --location --request POST 'http://localhost:5000/auth' \
    --header 'Content-Type: application/json' \
    --data-raw '{"username":"admin","role":"Admin"}'

will return a Bearer JWT token.

## access

    curl --location --request GET 'http://localhost:5000/protected/second' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFkbWluIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNjcyNDU2MjE3LCJleHAiOjE2NzI1NDI2MTd9.XhuGlgP-0fKFifyOslytf56_J6n_RYlotYaO10nLP0Q'
