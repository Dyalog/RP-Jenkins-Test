# Link.StripCaseCode

    files ← {opts} ⎕SE.Link.StripCaseCode files

If case codes is on (default is off), each file name will have a [case code](Link.CaseCode.md#what-is-a-case-code). 

If you set up a `beforeRead` hook when [creating a Link](Link.Create.md), Link will allow your prompt your hook take appropriate action before a file is imported. If the filename may have a case code. The *StripCaseCode* function is provided to remove case coding from any file name.

#### Arguments

- file name(s)

#### Result

- file name(s) without case code