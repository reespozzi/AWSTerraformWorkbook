Repo to track progress working through AWS and Terraform examples in a book. Remember to export AWS tokens into shell before running.

To run:
Ensure terraform is downloaded, using "brew install terraform" with homebrew.

Fill out envSetup tokens with your AWS tokens. Then run "chmod +x envSetup; source ./envSetup" in your terminal to set up your local environment.
Then you can go about the usual terraform commands to build the resources in AWS!
-terraform plan -out plan

-terraform apply "plan"
