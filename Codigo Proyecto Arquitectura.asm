
org 0x7c00          ; Dirección en memoria donde se carga el bootloader
bits 16             ; Modo real de 16 bits

start:
    jmp boot        ; Salta a la rutina de arranque

boot:
    cli             ; Desactiva las interrupciones
    cld             ; Limpia el indicador de dirección
    mov si, menu    ; Coloca la dirección del menú en SI
    call print_string  ; Muestra el menú inicial

    ; Leer opción del usuario
    call read_input
    cmp byte [buffer], '1' ; Compara la opción ingresada con '1' (Leer)
    je .read_option
    cmp byte [buffer], '2' ; Compara la opción ingresada con '2' (Escribir)
    je .write_option
    jmp boot           ; Si no es ninguna opción válida, regresa al menú

.read_option:
    ; Leer: Permite ingresar hasta 32 caracteres
    call read_text     ; Llama a la función para leer una cadena de texto
    jmp boot           ; Regresa al menú después de leer

.write_option:
    ; Escribir: Muestra las palabras almacenadas
    call print_text    ; Muestra el texto almacenado
    jmp boot           ; Regresa al menú después de mostrar

; Mensaje del menú
menu db "Seleccione una opción:", 0ah, 0dh
menu_option1 db "1. Leer", 0ah, 0dh
menu_option2 db "2. Escribir", 0ah, 0dh
menu_exit db "0. Salir", 0ah, 0dh, 0

; Buffer para almacenar la opción y las cadenas
buffer db 0
input_buffer db 32, 0  ; Max 32 caracteres para la cadena

; Subrutina para leer opción del usuario (un carácter)
read_input:
    mov ah, 0x00        ; Función BIOS para leer carácter del teclado
    int 0x16            ; Espera entrada de teclado y guarda el carácter en AL
    mov [buffer], al    ; Guarda el carácter leído en el buffer
    ret                 ; Retorna al llamador

; Subrutina para imprimir una cadena en pantalla
print_string:
    mov ax, 0xB800     ; Direccion de la memoria de video
    mov es, ax         ; ES apunta a la memoria de video

.next_char:
    lodsb              ; Carga el siguiente carácter de la cadena en AL
    or al, al          ; Si AL es 0, termina la cadena
    jz .done_print
    mov ah, 0x07       ; Atributo de color (blanco sobre negro)
    mov [es:di], ax    ; Escribe el carácter en la memoria de video
    add di, 2          ; Avanza dos bytes (uno para el carácter, otro para el atributo)
    jmp .next_char

.done_print:
    ret

; Subrutina para leer una cadena de caracteres (máximo 32)
read_text:
    mov di, input_buffer  ; DI apunta al buffer de entrada
    mov cx, 32            ; Máximo 32 caracteres

.read_char:
    mov ah, 0x00         ; Función de BIOS para leer carácter
    int 0x16             ; Llama a la interrupción de BIOS para leer del teclado
    cmp al, 0x0D         ; Si es Enter (0x0D), termina la lectura
    je .done_reading
    cmp al, 0x00         ; Si es '0', termina el programa
    je .exit_program
    mov [di], al         ; Almacena el carácter en el buffer
    inc di               ; Avanza al siguiente byte del buffer
    loop .read_char      ; Lee hasta 32 caracteres

.done_reading:
    mov byte [di], 0     ; Coloca un terminador nulo al final de la cadena
    ret

.exit_program:
    mov byte [di], 0     ; Coloca un terminador nulo y finaliza
    hlt                  ; Termina el programa

; Subrutina para mostrar la cadena almacenada
print_text:
    mov si, input_buffer  ; SI apunta al buffer de entrada
    call print_string     ; Imprime la cadena almacenada
    ret

times 510 - ($ - $$) db 0  ; Rellena el espacio restante con ceros para completar 512 bytes
dw 0xAA55            ; Firma del sector de arranque