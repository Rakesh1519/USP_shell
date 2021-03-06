%{
#include <stdio.h>
#include <stdlib.h>
#include "command.h"
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>
#include <pwd.h>

#define CYAN    "\x1b[36m"
#define RESET   "\x1b[0m"

%}

%token NOTOKEN GREAT NEWLINE 
%token WORD GREATGREAT PIPE 
%token AMPERSAND LESS GREATAMPERSAND
%token GREATGREATAMPERSAND
%%

goal: command_list 
	;


arg_list: 
	| arg_list WORD {insertArgument(current_simple_command,$2);}
	;

cmd_and_args: 
	| WORD {current_simple_command = malloc(sizeof(SimpleCommand));insertArgument(current_simple_command,$1);} arg_list 
	;

pipe_list: pipe_list PIPE cmd_and_args { insertSimpleCommand(current_command,current_simple_command); }
	| cmd_and_args { insertSimpleCommand(current_command,current_simple_command); }
	;

io_modifier: GREATGREAT WORD 
	| GREAT WORD {current_command->out_file = strdup($2);} 
	| GREATGREATAMPERSAND WORD 
	| GREATAMPERSAND WORD 
	| LESS WORD {current_command->in_file = strdup($2);}
	;

io_modifier_list: io_modifier_list io_modifier 
	|
	;	
background_optional:  AMPERSAND {current_command->background = 1;}
	| 
	;
command_line: pipe_list io_modifier_list background_optional NEWLINE 
	| NEWLINE 
	| error NEWLINE {yyerrok;} 
	;     
command_list :  command_list {current_command = calloc(1,sizeof(Command));} command_line {if(current_command!=NULL){execute(current_command);}}
	| 
	;

%%
#include"lex.yy.c"

int main()
{
	char cwd[1024];
	char host[64];
	struct passwd *pass;

	getcwd(cwd, sizeof(cwd));
	gethostname(host, sizeof(host));
	pass = getpwuid(getuid());

	printf("%s@%s:" CYAN "%s" RESET "$ ", pass->pw_name, host, cwd);
	yyparse();
}


