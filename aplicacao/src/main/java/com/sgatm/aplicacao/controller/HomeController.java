package com.sgatm_db.aplicacao.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String paginaInicial(HttpSession session, Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null) {
            return "redirect:/login";
        }

        model.addAttribute("cargo", cargo);
        model.addAttribute("nomeUsuario", session.getAttribute("nomeUsuario"));

        return "index";
    }
}