package com.sgatm_db.aplicacao.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model; // <-- IMPORTANTE
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String paginaInicial(HttpSession session, Model model) { // <-- Passamos o Model aqui
        if (session.getAttribute("funcionarioLogado") == null) {
            return "redirect:/login";
        }
        model.addAttribute("paginaAtiva", "inicio"); // <-- Adicionado
        return "index";
    }
}