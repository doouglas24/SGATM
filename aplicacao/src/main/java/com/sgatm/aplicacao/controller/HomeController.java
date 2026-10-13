package com.sgatm_db.aplicacao.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String paginaInicial(HttpSession session) {
        if (session.getAttribute("funcionarioLogado") == null) {
            return "redirect:/login";
        }
        return "index";
    }
}