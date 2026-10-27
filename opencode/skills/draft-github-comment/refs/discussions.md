# GitHub Discussions

Discussions are not issues: `gh issue comment` fails, and reads need GraphQL.
Resolve the discussion node ID first, then branch on repo vs org-level.

## Resolve the discussion ID

Repo discussion:
```sh
gh api graphql -f query='query{repository(owner:"<owner>",name:"<name>"){discussion(number:<n>){id}}}' \
  --jq '.data.repository.discussion.id'
```

Org-level discussion:
```sh
gh api graphql -f query='query{organization(login:"<org>"){discussion(number:<n>){id}}}' \
  --jq '.data.organization.discussion.id'
```

Every query below takes the same swap: replace
`repository(owner:"<owner>",name:"<name>")` with `organization(login:"<org>")`.

## Read the thread
<!-- §disc-read -->

```sh
gh api graphql -f query='query{repository(owner:"<owner>",name:"<name>"){discussion(number:<n>){
  title closed closedAt category{name} answerChosenAt isAnswered author{login} body
  comments(first:100){pageInfo{hasNextPage endCursor}
    nodes{id url author{login} createdAt body
      replies(first:100){nodes{id url author{login} createdAt body}}}}}}}'
```

Pagination: `comments(first:100, after:"<endCursor>")` until `hasNextPage` is false.
Feedback threads reach thousands of comments: fetch all before claiming a point is uncovered.
`comments(last:20)` is only for the pre-publish delta check, never for a coverage claim.

Status to report, in place of issue state: open or closed, answered (`isAnswered`) or not, category.

## Publish a comment
<!-- §disc-publish -->

Top-level:
```sh
jq -n --arg id '<discussion-id>' --rawfile body "$draftfile" \
  '{query:"mutation($id:ID!,$body:String!){addDiscussionComment(input:{discussionId:$id,body:$body}){comment{url}}}",
    variables:{id:$id,body:$body}}' \
  | gh api graphql --input -
```

Reply to a specific comment:
```sh
jq -n --arg id '<discussion-id>' --arg cid '<comment-id>' --rawfile body "$draftfile" \
  '{query:"mutation($id:ID!,$cid:ID!,$body:String!){addDiscussionReply(input:{discussionId:$id,discussionCommentId:$cid,body:$body}){reply{url}}}",
    variables:{id:$id,cid:$cid,body:$body}}' \
  | gh api graphql --input -
```

Never pre-check token scopes: `addDiscussionComment` succeeds without `write:discussion`.

On a scope error or `Could not resolve to a Discussion`: stop and ask, then
`gh auth refresh -s write:discussion` if the user agrees.
The "On failure" branches in `SKILL.md` cover this path too.

## Update a published comment
<!-- §disc-update -->

Match the node ID by URL, since the numeric ID is not usable in a mutation:
```sh
gh api graphql -f query='query{repository(owner:"<owner>",name:"<name>"){discussion(number:<n>){
  comments(last:25){nodes{id url}}}}}' \
  --jq '.data.repository.discussion.comments.nodes[] | select(.url|test("<numeric-comment-id>"))'
```

Then:
```sh
jq -n --arg id '<comment-node-id>' --rawfile body "$draftfile" \
  '{query:"mutation($id:ID!,$body:String!){updateDiscussionComment(input:{commentId:$id,body:$body}){comment{url}}}",
    variables:{id:$id,body:$body}}' \
  | gh api graphql --input -
```

An edited comment keeps its URL. Report the URL, not the mutation payload.
