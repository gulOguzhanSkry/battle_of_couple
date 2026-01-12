ERROR HANDLING RULES
Core Principle

Errors are not enemies to eliminate.
Errors are realities to manage.

A program must never crash because of an unhandled error.
Every possible failure must be anticipated and controlled.

Purpose of Error Handling

The goal of error handling is not to prevent errors from happening,
but to prevent errors from breaking the application.

An error should:

Be caught

Be understood

Be logged or communicated

Allow the application to continue safely

Try-Catch Philosophy
TRY block

The TRY block contains any operation that may fail due to external or uncontrollable factors:

File system access

Network requests

Database operations

User input parsing

API calls

Hardware or OS dependent operations

TRY means:

"This may fail, and I accept that possibility."

CATCH block

The CATCH block defines how the application reacts to failure.

It must:

Prevent application crash

Capture the error clearly

Provide meaningful feedback

Allow graceful recovery when possible

CATCH means:

"Failure is expected, and I am prepared."

Error Classification Rule

Specific errors must be handled specifically.
Generic errors must be handled generally.

Example mindset:

Known error → targeted handling

Unknown error → safe fallback handling

This preserves both precision and stability.

Golden Rule

No runtime error should terminate the application unexpectedly.

If a failure occurs, the system must remain stable.

Correct Developer Mindset

Wrong mindset:

"This code will not fail."

Correct mindset:

"This code may fail, and I am ready."

Where Error Handling Is Mandatory

Error handling must always be applied when working with:

File operations

Network communication

Databases

External services

User input validation

Mathematical operations that may be unsafe (division, parsing, casting)

Quality Indicator

The quality of software is not measured by how rarely it fails,
but by how gracefully it handles failure.

AI Instruction

When generating code:

Always assume external operations can fail.

Always protect risky operations with error handling.

Always prioritize application stability over optimistic execution.

Never ignore potential exceptions.

Always design recovery paths.

Final Summary

Error handling is not optional.
It is a fundamental responsibility of professional software design.

İstersen bunu:

Flutter özel kurallar

Backend API rules

Clean Architecture error policy

Mobile production checklist

Enterprise coding standard