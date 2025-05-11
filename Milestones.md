**Milestone 1:**

For initializing the project structure, I figured out that Aider doesn't able to execute shell commands to initialize the project strcuture, however he can run it throught /run. utilized OptoGPT to give introdcution about each technology, but failed to make optogpt(DeepSeek.R1) using the web search to craft a prompt that utitlize the best practices for writing a prompt for Aider that I can use in Aider to help me build a comperhensive execution plan with a progress tracker. Claude managed to make the prompt.

**Milestone 2:**

Faced an issue of rate limit when I was executing the commands that Aider asked me to run, then I figured out that he made me to connect to Finnhub twice with different ways. Faced synatx issues and after several attepmts, went to claude to fix.

**Milestone 3 & 4:**

Faced some errors, it takes several attempts before going to claude to fix it.

**Milestone 5:**

I felt like if Aider get lost, /code doesn't create files. It went well in the first time, the first test file get created successfuly, and it fixes the issues while running the test cases. However, when I wanted to continue adding more tests, it print out the content without creating the file and always ask for run mix test! Tried muliple times to direct him to create the files but with no luck.