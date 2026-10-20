package com.sgatm_db.aplicacao.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class LoginController {

    @GetMapping("/login")
    public String paginaLogin() {
        return "login";
    }

    @PostMapping("/login")
    public String autenticar(@RequestParam("email") String loginInput,
                             @RequestParam("senha") String senha,
                             HttpSession session,
                             Model model) {
        
        String input = loginInput != null ? loginInput.trim() : "";
        String pass = senha != null ? senha.trim() : "";

        String cargo = null;
        String nomeFuncionario = null;

        // Validação baseada nos IDs e Cargos definidos na Etapa 1 (Tabela FUNCIONARIO)
        if ("1".equals(input) && "Gerente@2026".equals(pass)) {
            cargo = "Gerente";
            nomeFuncionario = "Gerente Principal";
        } 
        else if ("2".equals(input) && "Atende@2026".equals(pass)) {
            cargo = "Atendente";
            nomeFuncionario = "Atendente do Sistema";
        } 
        else if ("3".equals(input) && "Tecnico@2026".equals(pass)) {
            cargo = "Tecnico";
            nomeFuncionario = "Técnico Responsável";
        } 
        else if ("4".equals(input) && "Outro@2026".equals(pass)) {
            cargo = "OutroSetor";
            nomeFuncionario = "Outro Setor";
        }

        if (cargo != null) {
            session.setAttribute("cargoUsuario", cargo);
            session.setAttribute("nomeUsuario", nomeFuncionario);
            return "redirect:/";
        }

        model.addAttribute("erro", "Credenciais inválidas! Utilize os IDs 1, 2, 3 ou 4.");
        return "login";
    }

    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate();
        return "redirect:/login";
    }
}