package com.sgatm_db.aplicacao.controller;

import com.sgatm_db.aplicacao.model.Equipamento;
import com.sgatm_db.aplicacao.repository.ClienteRepository;
import com.sgatm_db.aplicacao.repository.EquipamentoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import jakarta.servlet.http.HttpSession;

@Controller
public class EquipamentoController {

    @Autowired
    private EquipamentoRepository equipamentoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @GetMapping("/equipamentos")
    public String listarEquipamentos(HttpSession session, Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null) return "redirect:/login";
        if (!cargo.equals("Gerente") && !cargo.equals("Atendente")) {
            return "redirect:/?erro=Acesso Negado!";
        }

        model.addAttribute("equipamentos", equipamentoRepository.findAll());
        model.addAttribute("equipamento", new Equipamento());
        model.addAttribute("clientes", clienteRepository.findAll());
        return "equipamentos";
    }

    @PostMapping("/equipamentos")
    public String salvarEquipamento(@ModelAttribute Equipamento equipamento, HttpSession session) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null || (!cargo.equals("Gerente") && !cargo.equals("Atendente"))) {
            return "redirect:/login";
        }
        equipamentoRepository.save(equipamento);
        return "redirect:/equipamentos";
    }

    @GetMapping("/equipamentos/editar/{id}")
    public String carregarEdicaoEquipamento(@PathVariable Long id, HttpSession session, Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null || !cargo.equals("Gerente")) {
            return "redirect:/equipamentos?erro=Acesso Negado!";
        }
        Equipamento equipamento = equipamentoRepository.findById(id).orElse(null);
        model.addAttribute("equipamento", equipamento);
        model.addAttribute("equipamentos", equipamentoRepository.findAll());
        model.addAttribute("clientes", clienteRepository.findAll());
        return "equipamentos";
    }
}