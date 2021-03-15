$if(title)$
# $title$

$description$

$endif$
$for(header-includes)$
$header-includes$

$endfor$
$for(include-before)$
$include-before$

$endfor$
$if(toc)$
# $toc-title$
$table-of-contents$

$endif$
$body$
$for(include-after)$

$include-after$
$endfor$
