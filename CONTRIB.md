# Table of Contents
  - [Documentation](#documentation)
  - [Checklist before committing](#checklist-before-committing)

## Documentation

To regenerate docs: `make doc`

Documentation source is located under doc/ directory.  
The source is in Markdown with GFM output compatible pandoc extensions.

For source files, .in suffix is used.  
(Note that this requires passing the input type explicitly to pandoc).

## Checklist before committing

  - Check files with:
      - .sh files: ShellChecker
  - Regenerate docs if required
