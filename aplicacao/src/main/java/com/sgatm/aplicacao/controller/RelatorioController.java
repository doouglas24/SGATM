package com.sgatm_db.aplicacao.controller;

import com.sgatm_db.aplicacao.model.OrdemServico;
import com.sgatm_db.aplicacao.repository.OrdemServicoRepository;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@Controller
public class RelatorioController {

    @Autowired
    private OrdemServicoRepository ordemServicoRepository;

    @GetMapping("/relatorio")
    public String verRelatorio(@RequestParam(value = "status", required = false) String status,
                               HttpSession session, 
                               Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null) {
            return "redirect:/login";
        }

        List<OrdemServico> ordens;
        if (status != null && !status.isEmpty()) {
            ordens = ordemServicoRepository.findByStatus(status);
        } else {
            ordens = ordemServicoRepository.findAll();
        }

        model.addAttribute("ordens", ordens);
        model.addAttribute("statusSelecionado", status);
        return "relatorio-ordens"; 
    }

    @GetMapping("/caminho-protegido")
    public String acaoProtegida(HttpSession session) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        
        if (!"Gerente".equals(cargo)) {
            return "redirect:/?erro=Acesso Negado!";
        }
        
        return "sua-pagina";
    }
}