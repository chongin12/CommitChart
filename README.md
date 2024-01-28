# Commit Chart
Commit Chart is an API that displays the history of commits for each repository in a table format.\
(It only works in public repositories.)

## usage

```markdown
![](https://api.mosu.blog/{owner}/{repository})
```
Please modify the {owner} and {repository} parts of the code above appropriately and insert it into your readme.md file.

For example, 
```markdown
![](https://api.mosu.blog/chongin12/Problem_Solving)
```
shows [github.com/chongin12/Problem_Solving](github.com/chongin12/Problem_Solving) repository.\
Like this :
![](https://api.mosu.blog/chongin12/Problem_Solving)

## Path Parameters
### owner
The name of the owner or organization of that repository.
### repository
The name of that repository.

## Query Parameters
### since
YYYY-MM-DD format. (Default : Today - 365 days)
```markdown
![](https://api.mosu.blog/chongin12/Problem_Solving?since=2024-01-01)
```
![](https://api.mosu.blog/chongin12/Problem_Solving?since=2024-01-01)
### until
YYYY-MM-DD format. (Default : Today)
```markdown
![](https://api.mosu.blog/chongin12/Problem_Solving?since=2024-01-01&until=2024-01-28)
```
![](https://api.mosu.blog/chongin12/Problem_Solving?since=2024-01-01&until=2024-01-28)
### tz
Timezone. (Default : Asia/Seoul)
```markdown
![](https://api.mosu.blog/chongin12/Problem_Solving?since=2024-01-01&until=2024-01-28&tz=Asia/Seoul)
```
![](https://api.mosu.blog/chongin12/Problem_Solving?since=2024-01-01&until=2024-01-28&tz=Asia/Seoul)