%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char buffer[5000];
int pos = 0;

char switch_var[50];
char case_var[100][50];
char case_val[100][50];
char case_result[100][50];
char default_var[50];
char default_result[50];

int case_count = 0;
int has_default = 0;
%}

%%

"switch"|"case"|"default"|"break" {
    int len = yyleng;
    if (pos + len < sizeof(buffer) - 1) {
        memcpy(buffer + pos, yytext, len);
        pos += len;
    }
}

[a-zA-Z_][a-zA-Z0-9_]*|[0-9]+ {
    if (pos + yyleng < sizeof(buffer) - 1) {
        memcpy(buffer + pos, yytext, yyleng);
        pos += yyleng;
    }
}

[ \t\r\n]+ {
    if (pos < sizeof(buffer) - 1)
        buffer[pos++] = ' ';
}

. {
    if (pos < sizeof(buffer) - 1)
        buffer[pos++] = yytext[0];
}

%%

int main(void)
{
    printf("Enter switch-case statement (finish with }):\n");

    yylex();

    buffer[pos] = '\0';

    char *p = strstr(buffer, "switch");
    if (!p || !(p = strchr(p, '('))) {
        printf("Invalid switch statement!\n");
        return 1;
    }

    p++;
    while (*p == ' ') p++;

    int n = 0;
    while ((*p >= 'a' && *p <= 'z') ||
           (*p >= 'A' && *p <= 'Z') ||
           (*p >= '0' && *p <= '9') ||
           *p == '_') {
        if (n < 48) switch_var[n++] = *p;
        p++;
    }
    switch_var[n] = '\0';

    p = strstr(buffer, "case");

    while (p && case_count < 100) {
        p += 4;
        while (*p == ' ') p++;

        char *end;
        strtol(p, &end, 10);

        if (end == p) break;

        n = 0;
        while (*p >= '0' && *p <= '9') {
            if (n < 48) case_val[case_count][n++] = *p;
            p++;
        }
        case_val[case_count][n] = '\0';

        p = strchr(p, ':');
        if (!p) break;
        p++;

        while (*p == ' ') p++;

        n = 0;
        while ((*p >= 'a' && *p <= 'z') ||
               (*p >= 'A' && *p <= 'Z') ||
               *p == '_') {
            if (n < 48) case_var[case_count][n++] = *p;
            p++;
        }
        case_var[case_count][n] = '\0';

        p = strchr(p, '=');
        if (!p) break;
        p++;

        while (*p == ' ') p++;

        n = 0;
        while ((*p >= '0' && *p <= '9') || *p == '-') {
            if (n < 48) case_result[case_count][n++] = *p;
            p++;
        }
        case_result[case_count][n] = '\0';

        case_count++;
        p = strstr(p, "case");
    }

    p = strstr(buffer, "default");

    if (p) {
        has_default = 1;
        p = strchr(p, ':');

        if (p) {
            p++;
            while (*p == ' ') p++;

            n = 0;
            while ((*p >= 'a' && *p <= 'z') ||
                   (*p >= 'A' && *p <= 'Z') ||
                   *p == '_') {
                if (n < 48) default_var[n++] = *p;
                p++;
            }
            default_var[n] = '\0';

            p = strchr(p, '=');
            if (p) {
                p++;
                while (*p == ' ') p++;

                n = 0;
                while ((*p >= '0' && *p <= '9') || *p == '-') {
                    if (n < 48) default_result[n++] = *p;
                    p++;
                }
                default_result[n] = '\0';
            }
        }
    }

    printf("\nThree Address Code:\n\n");

    for (int i = 0; i < case_count; i++)
        printf("if %s == %s goto L%d\n",
               switch_var, case_val[i], i + 1);

    if (has_default)
        printf("goto L%d\n", case_count + 1);
    else
        printf("goto Lend\n");

    for (int i = 0; i < case_count; i++) {
        printf("\nL%d: %s = %s\n",
               i + 1, case_var[i], case_result[i]);
        printf("goto Lend\n");
    }

    if (has_default)
        printf("\nL%d: %s = %s\n",
               case_count + 1, default_var, default_result);

    printf("\nLend:\n");

    return 0;
}

int yywrap(void)
{
    return 1;
}