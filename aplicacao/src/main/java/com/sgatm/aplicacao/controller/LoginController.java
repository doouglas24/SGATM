package com.sgatm_db.aplicacao.controller;

import com.sgatm_db.aplicacao.model.Funcionario;
import com.sgatm_db.aplicacao.repository.FuncionarioRepository;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class LoginController {

    @Autowired
    private FuncionarioRepository funcionarioRepository;

    @GetMapping("/login")
    public String paginaLogin() {
        return "login";
    }

    @PostMapping("/login")
    public String autenticar(@RequestParam String email, 
                             @RequestParam String senha, 
                             HttpSession session, 
                             Model model) {
        
        Funcionario funcionario = funcionarioRepository.findByEmail(email);

        if (funcionario != null && funcionario.getSenha().equals(senha)) {
            // Guarda o funcionário na sessão
            session.setAttribute("funcionarioLogado", funcionario);
            return "redirect:/";
        }

        model.addAttribute("erro", "E-mail ou palavra-passe inválidos!");
        return "login";
    }

    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate();
        return "redirect:/login";
    }
}