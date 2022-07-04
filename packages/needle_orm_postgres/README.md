# needle_orm_postgres.dart

postgres support for needle

# IMPORTANT

when use `IN` statement , the param name must be followed by an blank ' ' !!!

```
'SELECT * FROM books where id in @idList '
```

You've been warned: THE FOLLOWING IS WRONG!!!

```
'SELECT * FROM books where id in @idList'
```
